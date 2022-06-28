variable "aws_region" {
  type = string
}

variable "certificate-private_key" {
  type = string
  sensitive = true
}
variable "certificate-ssc" {
  type = string
  sensitive = true
}
variable "certificate-ca_bundle" {
  type = string
  sensitive = true
}

variable "aws_vpc_ssh_public_key_dev" {
  type = string
  sensitive = true
}
variable "aws_vpc_ssh_public_key_prod" {
  type = string
  sensitive = true
}
variable "node_license-dev-01" {
  type = string
  sensitive = true
}
variable "node_license-dev-02" {
  type = string
  sensitive = true
}
variable "node_license-prod-01" {
  type = string
  sensitive = true
}
variable "node_license-prod-02" {
  type = string
  sensitive = true
}