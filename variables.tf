variable "aws_region" {
    description = "The AWS region to deploy resources."
    type = string
}

variable "s3_bucket_id" {
    description = "ID of the S3 bucket to store Lambda function code."
}

variable "s3_data_bucket_id" {
  description = "The S3 bucket ID to receive notifications."
  type = string
}

variable "s3_data_bucket_arn" {
    description = "The ARN of the S3 bucket to receive notifications."
}

variable "from_address" {
  description = "From email address for Order notifications."
  type = string
}

variable "to_address" {
  description = "To email address for Order notifications."
  type = string  
}

variable "email_from_identiy_arn" {
  description = "ARN of the email identity from send email to."
}

variable "email_to_identiy_arn" {
  description = "ARN of the email identity to send email to."
}