terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_instance" "test_t3_micro" {
  ami           = "ami-01c647eace872fc02"
  instance_type = "t2.micro"

}