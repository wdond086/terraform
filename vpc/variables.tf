variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.5.0/24"]
}

variable "public_subnet_cidrs_for_each" {
  type = map(object({
    availability_zone : string
  }))
  description = "Public Subnet CIDR values and the AZ"
  default = {
    "10.0.7.0/24" = {
      availability_zone = "us-east-1c"
    },
    "10.0.8.0/24" = {
      availability_zone = "us-east-1d"
    },
    "10.0.9.0/24" = {
      availability_zone = "us-east-1e"
    },
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.3.0/24", "10.0.4.0/24", "10.0.6.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ami" {
  description = "Amazon machine image to use for ec2 instance"
  type        = string
  default     = "ami-01c647eace872fc02" # Ubuntu 20.04 LTS // us-east-1
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "region" {
  description = "Default region for provider"
  type        = string
  default     = "us-east-1"
}