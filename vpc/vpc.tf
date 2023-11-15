# Creates a VPC with an attached internet gateway, and four subnets, two public (Across 2 AZ) and two private (Across 2 AZ)

resource "aws_vpc" "custom_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "custom_vpc"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index % length(var.azs))

  tags = {
    Name        = "Public Subnet ${count.index + 1}"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
    Meta-Arg    = "count"
  }
}

# This will use for_each
resource "aws_subnet" "public_subnets_2" {
  for_each          = var.public_subnet_cidrs_for_each
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = each.key
  availability_zone = each.value.availability_zone

  tags = {
    Name        = "Public Subnet at ${each.key}"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
    Meta-Arg    = "for_each"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index % length(var.azs))

  tags = {
    Name        = "Private Subnet ${count.index + 1}"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
    Meta-Arg    = "count"
  }
}

resource "aws_internet_gateway" "custom_vpc_internet_gw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name        = "custom_vpc_ig"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route_table" "custom_vpc_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name        = "custom_vpc_rt"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route" "custom_vpc_ig_route" {
  route_table_id         = aws_route_table.custom_vpc_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.custom_vpc_internet_gw.id
  depends_on             = [aws_route_table.custom_vpc_rt]
}

resource "aws_route_table_association" "public_subnet_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.custom_vpc_rt.id
}

resource "aws_route_table_association" "public_subnets_2_rt_association" {
  for_each       = var.public_subnet_cidrs_for_each
  subnet_id      = aws_subnet.public_subnets_2[each.key].id
  route_table_id = aws_route_table.custom_vpc_rt.id
}

# Creating an NACL to only allow ingress traffic to private subnet 2 from public subnet 2
resource "aws_network_acl" "private_subnet_2_nacl" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name        = "NACL to allow traffic between private subnet 2 and public subnet 2"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "true"
  }
}

# Retrieving private subnet 2
data "aws_subnet" "private_subnet_2" {
  tags = {
    Name        = "Private Subnet 2"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
    Meta-Arg    = "count"
  }
}

data "aws_subnet" "public_subnet_2" {
  tags = {
    Name        = "Public Subnet 2"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
    Meta-Arg    = "count"
  }
}

resource "aws_network_acl_association" "private_subnet_2_nacl_assoc" {
  network_acl_id = aws_network_acl.private_subnet_2_nacl.id
  subnet_id      = data.aws_subnet.private_subnet_2.id
}

resource "aws_network_acl_rule" "private_subnet_2_nacl_ingress_rule" {
  network_acl_id = aws_network_acl.private_subnet_2_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = data.aws_subnet.public_subnet_2.cidr_block
  icmp_type      = 8
  icmp_code      = 0
}

resource "aws_network_acl_rule" "private_subnet_2_nacl_ingress_default" {
  network_acl_id = aws_network_acl.private_subnet_2_nacl.id
  rule_number    = 101
  egress         = false
  protocol       = "all"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = -1
  to_port        = -1
}

resource "aws_network_acl_rule" "private_subnet_2_nacl_egress_rule" {
  network_acl_id = aws_network_acl.private_subnet_2_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = data.aws_subnet.public_subnet_2.cidr_block
  icmp_type      = 0
  icmp_code      = 0
}

resource "aws_network_acl_rule" "private_subnet_2_nacl_egress_rule_default" {
  network_acl_id = aws_network_acl.private_subnet_2_nacl.id
  rule_number    = 101
  egress         = true
  protocol       = "all"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = -1
  to_port        = -1
}
