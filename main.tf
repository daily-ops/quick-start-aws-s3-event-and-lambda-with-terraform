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

module "lambda_s3_notifications" {
    source = "./lambda"
    aws_region = var.aws_region
    s3_bucket_id = var.s3_bucket_id
    s3_data_bucket_arn = var.s3_data_bucket_arn
    s3_data_bucket_id = var.s3_data_bucket_id
    from_address = var.from_address
    to_address = var.to_address
    email_from_identiy_arn = var.email_from_identiy_arn
    email_to_identiy_arn = var.email_to_identiy_arn
    ses_aws_region = var.aws_region

}
resource "aws_s3_bucket_notification" "data-trigger" {
    bucket = var.s3_data_bucket_id

    lambda_function {
        lambda_function_arn = module.lambda_s3_notifications.function_arn
        events              = ["s3:ObjectCreated:*"]
        filter_prefix       = "receipts/"
        filter_suffix       = ".txt"
    }
}

resource "aws_lambda_permission" "data-trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_s3_notifications.function_name
  principal = "s3.amazonaws.com"
  source_arn = var.s3_data_bucket_arn
}