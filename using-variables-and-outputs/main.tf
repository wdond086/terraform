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

provider "aws" {
  region = var.region
}

resource "aws_security_group" "ec2_instances_sg" {
  name = "instance-security-group"
}

resource "aws_iam_role" "ec2-iam-role" {
  name = "ec2-iam-role"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Action" = "sts:AssumeRole"
        "Effect" = "Allow"
        "Sid"    = ""
        "Pricipal" = {
          "Service" = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Same thing as above but using data source
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2-iam-role-thru-data-source" {
  name               = "ec2-iam-role-2-thru-data-source"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2-iam-role.name
}

data "aws_iam_policy_document" "ec2-instance-profile-policy-document" {
  statement {
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.web-app-bucket.bucket]
  }
}

resource "aws_iam_role_policy" "ec2-iam-policy" {
  name = "ec2-iam-policy"
  role = aws_iam_role.ec2-iam-role.name
  policy = jsonencode({
    "Statement" = [
      {
        "Action" = "s3:*"
        "Effect" = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2-iam-policy-thru-data-source" {
  name   = "ec2-iam-policy-thru-data-source"
  role   = aws_iam_role.ec2-iam-role.name
  policy = data.aws_iam_policy_document.ec2-instance-profile-policy-document.json
}

# Rule to allows ingress traffic from anywhere port 8080 to port 8080
resource "aws_security_group_rule" "allow_http_inbound_to_ec2_instances" {
  type              = "ingress"
  security_group_id = aws_security_group.ec2_instances_sg.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "ec2_instance_1" {
  ami                  = var.ami
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.ec2_instances_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.id
  user_data            = <<-EOF
              #!/bin/bash
              echo "Hello, World from instance 1" > index.html
              python3 -m http.server 8080 &
              EOF

  depends_on = [
    aws_iam_instance_profile.ec2-instance-profile,
  ]
}

# Example using count
resource "aws_instance" "ec2_instance_count_example" {
  count                = 3 # Will create 3 of these instances
  ami                  = var.ami
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.ec2_instances_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.id
  user_data            = <<-EOF
              #!/bin/bash
              echo "Hello, World from instance 1" > index.html
              python3 -m http.server 8080 &
              EOF

  depends_on = [
    aws_iam_instance_profile.ec2-instance-profile,
  ]

  tags = {
    Name = "Server ${count.index}"
  }
}

resource "aws_instance" "ec2_instance_2" {
  ami                  = var.ami
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.ec2_instances_sg.name]
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.id
  user_data            = <<-EOF
              #!/bin/bash
              echo "Hello, World from instance 2" > index.html
              python3 -m http.server 8080 &
              EOF

  depends_on = [
    aws_iam_instance_profile.ec2-instance-profile,
  ]
}

resource "aws_s3_bucket" "web-app-bucket" {
  bucket_prefix = var.bucket_prefix # Creates a unique bucket name beginning with the specified prefix.
  force_destroy = true              # Indicates all objects (including any locked objects) should be deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error.
  tags = {
    name       = "s3_bucket"
    environmet = "dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "web-app-bucket-boc" {
  bucket = aws_s3_bucket.web-app-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "web-app-bucket-acl" {
  bucket     = aws_s3_bucket.web-app-bucket.id
  depends_on = [aws_s3_bucket_ownership_controls.web-app-bucket-boc]
  acl        = "private"
}

resource "aws_s3_bucket_versioning" "web-app-bucket-versioning" {
  bucket = aws_s3_bucket.web-app-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "web-app-bucket-sse-config" {
  bucket = aws_s3_bucket.web-app-bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_security_group" "alb_security_group" {
  name = "alb_security_group"
}

# Allows traffic in from anywhere from 80 to port 80
resource "aws_security_group_rule" "alb_security_group_allow_http_inbound_rule" {
  security_group_id = aws_security_group.alb_security_group.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_security_group_allow_http_outbound_rule" {
  security_group_id = aws_security_group.alb_security_group.id
  type              = "egress"
  from_port         = 0    # Translates to all
  to_port           = 0    # Translates to all
  protocol          = "-1" # Translates to all
  cidr_blocks       = ["0.0.0.0/0"]
}

# Data references an existing resource in AWS like the default VPC, or the default subnet
# To retrieve the default VPC id
data "aws_vpc" "default_vpc" {
  default = "true"
}

# To retrieve the default subnet id of the default VPC
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

# The application load balancer 
resource "aws_alb" "web-app-alb" {
  name               = "web-app-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default_subnets.ids
  security_groups    = [aws_security_group.alb_security_group.id]
}

resource "aws_alb_listener" "web-app-alb-listener" {
  load_balancer_arn = aws_alb.web-app-alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found => :-("
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "web-app-alb-tg" {
  name     = "web-app-alb-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_alb_target_group_attachment" "ec2_instance_1_tg_attachment" {
  target_group_arn = aws_lb_target_group.web-app-alb-tg.arn
  target_id        = aws_instance.ec2_instance_1.id
  port             = 8080
}

resource "aws_alb_target_group_attachment" "ec2_instance_2_tg_attachment" {
  target_group_arn = aws_lb_target_group.web-app-alb-tg.arn
  target_id        = aws_instance.ec2_instance_2.id
  port             = 8080
}

resource "aws_alb_listener_rule" "web-app-alb-listener-rule" {
  listener_arn = aws_alb_listener.web-app-alb-listener.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-app-alb-tg.arn
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage = 20
  # This allows any minor version within the major engine_version
  # defined below, but will also result in allowing AWS to auto
  # upgrade the minor version of your DB. This may be too risky
  # in a real production environment.
  auto_minor_version_upgrade = true
  storage_type               = "standard"
  engine                     = "postgres"
  engine_version             = "12"
  instance_class             = "db.t2.micro"
  db_name                    = var.db_name
  username                   = var.db_user
  password                   = var.db_pass # I know, very bad. But its for a test
  skip_final_snapshot        = true
}

resource "aws_route53_zone" "primary" {
  name = var.domain
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_alb.web-app-alb.dns_name
    zone_id                = aws_alb.web-app-alb.zone_id
    evaluate_target_health = true
  }
}