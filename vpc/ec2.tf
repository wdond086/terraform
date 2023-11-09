# Create EC2 instances in each of the subnets we created

# SG granting HTTP and SSH
resource "aws_security_group" "ec2_web_and_ssh_access_sg" {
  name        = "ec2_web_and_ssh_access_sg"
  description = "Allow HTTP and SSH inbound, and all outbound"
  vpc_id      = aws_vpc.custom_vpc.id
}

# Rule to allow HTTP ingress traffic
resource "aws_security_group_rule" "ec2_ingress_http_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.ec2_web_and_ssh_access_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["142.188.147.45/32"]
  description       = "Allows HTTP traffic on port 80 from my IP"
}

# Rule to allow HTTP ingress traffic
resource "aws_security_group_rule" "ec2_ingress_ssh_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.ec2_web_and_ssh_access_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  # cidr_blocks       = ["142.188.147.45/32"]
  # cidr for instance connect retrieved from https://ip-ranges.amazonaws.com/ip-ranges.json
  cidr_blocks       = ["142.188.147.45/32", "18.206.107.24/29"] # For testing
  description       = "Allows SSH traffic on port 22 from my IP"
}

resource "aws_security_group_rule" "ec2_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.ec2_web_and_ssh_access_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allows all egress traffic"
}

# Creating the public EC2 instances
resource "aws_instance" "public_instances" {
  count                       = length(var.public_subnet_cidrs)
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.ec2_web_and_ssh_access_sg.id]
  subnet_id                   = element(aws_subnet.public_subnets[*].id, count.index)
  associate_public_ip_address = true
  user_data                   = <<-EOF
            #!/bin/bash
            echo "Hello, World from public instance ${count.index + 1}" > index.html
            python3 -m http.server 80
            EOF
  tags = {
    Name        = "EC2 instance in Public Subnet: ${count.index + 1}"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

# Creating another SG to give access to the private instances from the SG of the Public instances
resource "aws_security_group" "private_instance_sg" {
  name        = "private_instance_sg"
  description = "Allow HTTP and SSH inbound, and all outbound"
  vpc_id      = aws_vpc.custom_vpc.id
}

resource "aws_security_group_rule" "private_http_access_sg" {
  type              = "ingress"
  security_group_id = aws_security_group.private_instance_sg.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = aws_security_group.ec2_web_and_ssh_access_sg.id
  # cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allows HTTP traffic on port 80 from the SG of the public instances"
}

resource "aws_security_group_rule" "private_ping_access_rule" {
  type              = "ingress"
  security_group_id = aws_security_group.private_instance_sg.id
  from_port         = 8
  to_port           = 0
  protocol          = "icmp"
  source_security_group_id = aws_security_group.ec2_web_and_ssh_access_sg.id
  # cidr_blocks       = ["10.0.0.0/16"]
  description       = "Allows ping access from the SG of the public instances"
}

resource "aws_security_group_rule" "private_instance_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.private_instance_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allows all egress traffic"
}

# Creating the private instances
resource "aws_instance" "private_instances" {
  count = length(var.private_subnet_cidrs)
  ami = var.ami
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.private_instance_sg.id]
  subnet_id = element(aws_subnet.private_subnets[*].id, count.index)
  associate_public_ip_address = false
  user_data                   = <<-EOF
            #!/bin/bash
            echo "Hello, World from private instance ${count.index + 1}" > index.html
            python3 -m http.server 80
            EOF
  tags = {
    Name        = "EC2 instance in Private Subnet: ${count.index + 1}"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}