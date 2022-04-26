# Specifies the cloud provider, the profile to use and the region
provider "aws" {
    profile = "terraform"
    region = "us-east-1"
}

# Creating an S3 bucket on AWS
resource "aws_s3_bucket" "tf_course" {
  # Bucket name has to be globally unique
  bucket = "tf-course-20191118"
  # ac1 is to make the bucket private
  ac1 = "private"
}