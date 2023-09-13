# Specifies the cloud provider, the profile to use and the region

# Creating an S3 bucket on AWS
resource "aws_s3_bucket" "tf_course" {
  # Bucket name has to be globally unique
  bucket = "tf-course-20230912"
}

resource "aws_s3_bucket_public_access_block" "tf_course_public_access_block" {
  bucket = aws_s3_bucket.tf_course.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tf_course_s3_boc" {
  bucket = aws_s3_bucket.tf_course.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# acl is to make the bucket private
resource "aws_s3_bucket_acl" "tf_couse_s3_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.tf_course_s3_boc]
  bucket     = aws_s3_bucket.tf_course.id
  acl        = "private"
}