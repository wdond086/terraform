terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
}

provider "aws" {
    profile = "sa-associate"
    region = "us-east-1"
}

resource "aws_s3_bucket" "tfcourse-terraform-state" {
  bucket = "tfcourse-terraform-state"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "tfcourse-terraform-state-boc" {
  bucket = aws_s3_bucket.tfcourse-terraform-state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "tfcourse-terraform-state-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.tfcourse-terraform-state-boc]
  bucket = aws_s3_bucket.tfcourse-terraform-state.id
  acl = "private"
}

resource "aws_s3_bucket_versioning" "tfcourse-terraform-state-versioning" {
  bucket = aws_s3_bucket.tfcourse-terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "tfcourse-terraform-state-key" {
  description = "Key used to encrypt tfcourse terraform state"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfcourse-terraform-state-encryption-config" {
  bucket = aws_s3_bucket.tfcourse-terraform-state.id
  rule {
    apply_server_side_encryption_by_default {
      # kms_master_key_id = aws_kms_key.tfcourse-terraform-state-key.arn
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tfcourse-terraform-state-locks" {
  name = "tfcourse-terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}