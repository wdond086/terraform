# Creates a VPC with an attached internet gateway, and four subnets, two public (Across 2 AZ) and two private (Across 2 AZ)

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "ca-central-1"
  region = "ca-central-1"
}
resource "aws_vpc" "custom_vpc" {
  provider             = aws.us-east-1
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "custom_vpc"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_vpc" "ca_central_vpc" {
  provider             = aws.ca-central-1
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "ca_central_custom_vpc"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "us_east_vpc_sg_ingress_rule" {
  provider          = aws.us-east-1
  security_group_id = aws_vpc.custom_vpc.default_security_group_id
  cidr_ipv4         = aws_vpc.ca_central_vpc.cidr_block
  # cidr_ipv4 = "10.1.0.0/16"
  from_port   = 8
  to_port     = 0
  ip_protocol = "icmp"
}

resource "aws_vpc_security_group_ingress_rule" "ca_central_vpc_sg_ingress_rule" {
  provider          = aws.ca-central-1
  security_group_id = aws_vpc.ca_central_vpc.default_security_group_id
  cidr_ipv4         = aws_vpc.custom_vpc.cidr_block
  # cidr_ipv4 = "10.0.0.0/16"
  from_port   = 8
  to_port     = 0
  ip_protocol = "icmp"
}

data "aws_caller_identity" "peer" {
  provider = aws.ca-central-1
}

data "aws_caller_identity" "main" {
  provider = aws.us-east-1
}

resource "aws_vpc_peering_connection" "peering_connection" {
  peer_owner_id = data.aws_caller_identity.peer.id
  vpc_id        = aws_vpc.custom_vpc.id
  peer_vpc_id   = aws_vpc.ca_central_vpc.id
  peer_region   = "ca-central-1"
  auto_accept   = false
  depends_on    = [aws_vpc.ca_central_vpc, aws_vpc.custom_vpc]

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "peering_connection_accepter" {
  provider                  = aws.ca-central-1
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_subnet" "ca_central_public_subnet" {
  provider          = aws.ca-central-1
  vpc_id            = aws_vpc.ca_central_vpc.id
  cidr_block        = "10.1.0.0/24"
  availability_zone = "ca-central-1a"

  tags = {
    Name        = "CA Central Public Subnet 1"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
    Meta-Arg    = "count"
  }
}

resource "aws_subnet" "public_subnets" {
  provider          = aws.us-east-1
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
  provider          = aws.us-east-1
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
  provider          = aws.us-east-1
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
  provider = aws.us-east-1
  vpc_id   = aws_vpc.custom_vpc.id

  tags = {
    Name        = "custom_vpc_ig"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_internet_gateway" "ca_central_internet_gw" {
  provider = aws.ca-central-1
  vpc_id   = aws_vpc.ca_central_vpc.id

  tags = {
    Name        = "custom_vpc_ig"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route_table" "custom_vpc_rt" {
  provider = aws.us-east-1
  vpc_id   = aws_vpc.custom_vpc.id

  tags = {
    Name        = "custom_vpc_rt"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route_table" "ca_central_vpc_rt" {
  provider = aws.ca-central-1
  vpc_id   = aws_vpc.ca_central_vpc.id

  tags = {
    Name        = "custom_vpc_rt"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_route" "custom_vpc_ig_route" {
  provider               = aws.us-east-1
  route_table_id         = aws_route_table.custom_vpc_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.custom_vpc_internet_gw.id
  depends_on             = [aws_route_table.custom_vpc_rt]
}

resource "aws_route" "us_east_peering_connection_rule" {
  provider                  = aws.us-east-1
  route_table_id            = aws_route_table.custom_vpc_rt.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
  depends_on                = [aws_vpc_peering_connection.peering_connection, aws_vpc.custom_vpc]
}

resource "aws_route" "ca_central_peering_connection_rule" {
  provider                  = aws.ca-central-1
  route_table_id            = aws_route_table.ca_central_vpc_rt.id
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection.id
  depends_on                = [aws_vpc_peering_connection.peering_connection, aws_vpc.ca_central_vpc]
}

resource "aws_route" "ca_central_custom_vpc_ig_route" {
  provider               = aws.ca-central-1
  route_table_id         = aws_route_table.ca_central_vpc_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ca_central_internet_gw.id
  depends_on             = [aws_route_table.ca_central_vpc_rt]
}

resource "aws_route_table_association" "public_subnet_association" {
  provider       = aws.us-east-1
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.custom_vpc_rt.id
}

resource "aws_route_table_association" "public_subnets_2_rt_association" {
  provider       = aws.us-east-1
  for_each       = var.public_subnet_cidrs_for_each
  subnet_id      = aws_subnet.public_subnets_2[each.key].id
  route_table_id = aws_route_table.custom_vpc_rt.id
}

resource "aws_route_table_association" "ca_central_public_subnet_association" {
  provider       = aws.ca-central-1
  subnet_id      = aws_subnet.ca_central_public_subnet.id
  route_table_id = aws_route_table.ca_central_vpc_rt.id
}

# Creating an NACL to only allow ingress traffic to private subnet 2 from public subnet 2
resource "aws_network_acl" "private_subnet_2_nacl" {
  provider = aws.us-east-1
  vpc_id   = aws_vpc.custom_vpc.id
  tags = {
    Name        = "NACL to allow traffic between private subnet 2 and public subnet 2"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "true"
  }
}

# Retrieving private subnet 2
data "aws_subnet" "private_subnet_2" {
  provider   = aws.us-east-1
  depends_on = [aws_subnet.private_subnets]
  tags = {
    Name        = "Private Subnet 2"
    Project     = "sa_vpc"
    Terraform   = "true"
    Environment = "dev"
    Meta-Arg    = "count"
  }
}

data "aws_subnet" "public_subnet_2" {
  provider   = aws.us-east-1
  depends_on = [aws_subnet.public_subnets]
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
  provider       = aws.us-east-1
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
  provider       = aws.us-east-1
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
  provider       = aws.us-east-1
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
  provider       = aws.us-east-1
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
  provider       = aws.us-east-1
}
