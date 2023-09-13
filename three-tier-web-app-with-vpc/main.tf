terraform {
  backend "s3" {
    bucket = "tfcourse-terraform-state"
    key = "three-tier-web-app-with-vpc/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tfcourse-terraform-state-locking"
    encrypt = true
  }

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}