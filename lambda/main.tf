terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "archive_file" "handle_s3_notification" {
  type        = "zip"
  source_file = "${path.module}/functions/handle_s3_notifications.py"
  output_path = "${path.module}/functions/handle_s3_notifications.zip"
}

resource "aws_s3_object" "handle_s3_notification" {
  bucket = var.s3_bucket_id

  key    = "handle_s3_notifications.zip"
  source = data.archive_file.handle_s3_notification.output_path

  etag = filemd5(data.archive_file.handle_s3_notification.output_path)
}

resource "aws_lambda_function" "handle_s3_notification" {
  function_name = "S3NotificationsFunction"

  s3_bucket = var.s3_bucket_id
  s3_key    = aws_s3_object.handle_s3_notification.key

  runtime = "python3.9"
  handler = "handle_s3_notifications.lambda_handler"

  source_code_hash = data.archive_file.handle_s3_notification.output_base64sha256
  
  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      SES_AWS_REGION = var.ses_aws_region
      FROM_ADDRESS = var.from_address
      TO_ADDRESS = var.to_address
    }
  }
}


resource "aws_cloudwatch_log_group" "handle_s3_notification" {
  # checkov:skip=CKV_AWS_338: ADD REASON: No requirement to retain logs for learning purposes
  # checkov:skip=CKV_AWS_158: ADD REASON: Only for learning purposes, no encryption needed
  name = "/aws/lambda/${aws_lambda_function.handle_s3_notification.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_s3_notifications_handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_notifications_handler_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_notifications_handler_policy.arn
}

resource "aws_iam_policy" "lambda_s3_notifications_handler_policy" {
  name        = "lambda_s3_notifications_handler_policy"
  description = "Allow lambda to access SES"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ses:SendEmail",
        ],
        Resource = [
          "${var.email_to_identiy_arn}",
          "${var.email_from_identiy_arn}",
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_notifications_handler_data_access_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_notifications_handler_data_access_policy.arn
}

resource "aws_iam_policy" "lambda_s3_notifications_handler_data_access_policy" {
  name        = "lambda_s3_notifications_handler_data_access_policy"
  description = "Allow lambda to access S3 data bucket"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
        ],
        Resource = [
          "${var.s3_data_bucket_arn}/*",
        ],
      },
    ],
  })
}

