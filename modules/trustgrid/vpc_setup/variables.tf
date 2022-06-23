variable "aws_region" {
    type = string
    description = "AWS region to deploy"
}

variable "primary_az" {
    type = string
    description = "Primary AWS Availability Zone to deploy"
}

variable "secondary_az" {
    type = string
    description = "Secondary AWS Availability Zone to deploy"
}

variable "customer_name" {
    type = string
    description = "short name for demo customer"
}

variable "public_key" {
    type = string
    description = "public key of key pair for login"
}

variable "ssh_ips" {
    type = list(string)
    description = "list of IPs allowed to SSH"
    default = []
}

variable tags {
  default = {}
  type = map(string)
}