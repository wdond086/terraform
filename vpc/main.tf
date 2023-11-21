terraform {
  backend "s3" {
    bucket         = "tfcourse-terraform-state"                      # The bucket where the state is stored
    key            = "three-tier-web-app-with-vpc/terraform.tfstate" # Where within the bucket the state will be stored
    region         = "us-east-1"
    dynamodb_table = "tfcourse-terraform-state-locking" # The table where the lock is saved
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}