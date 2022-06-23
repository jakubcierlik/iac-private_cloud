variable "aws_region" {
    type = string
}

variable "primary_az" {
    type = string
}

variable "secondary_az" {
    type = string
}

variable "licenses" {
    type = list(string)
}

variable "ssh_public_key" {
    type = string
}

variable "certificate-private_key" {
    type = string
}

variable "certificate-ssc" {
    type = string
}

variable "certificate-ca_bundle" {
    type = string
}

variable "env" {
    type = string
}

variable "customer_name" {
    type = string
}

variable enroll_endpoint {
  type        = string
  description = "Determines which Trustgrid Tenant the node is registered to"
  default     = "https://keymaster.trustgrid.io/v2/enroll"
}

