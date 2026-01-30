# this needs to be run first
# in order to create the remote state for terraform
module "global_variables" {
  source = "../modules/global_variables"
}

provider "aws" {
  region = module.global_variables.aws_region
}

terraform {
  required_version = ">= 1.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "{{ copier__terraform_state_name }}"

  # Allows deleting the bucket even if it contains objects.
  # This is useful for teardown environments.
  force_destroy = true
  
  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state" {
  name           = "{{ copier__terraform_state_name }}"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    "Name" = "DynamoDB Terraform State Lock Table"
  }
}
