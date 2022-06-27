variable "certificate-private_key" {}
variable "certificate-ssc" {}
variable "certificate-ca_bundle" {}

variable "aws_vpc_ssh_public_key_prod" {}
variable "aws_vpc_ssh_public_key_dev" {}
variable "node_license-prod-01" {}
variable "node_license-prod-02" {}
variable "node_license-dev-01" {}
variable "node_license-dev-02" {}


module "trustgrid" {
  source = "../modules/trustgrid/trustgrid_ha_env"
  aws_region = "us-west-2"
  customer_name = "l3av"
  env = "prod"
  certificate-ca_bundle = var.certificate-ca_bundle
  certificate-private_key = var.certificate-private_key
  certificate-ssc = var.certificate-ssc
  licenses = [var.node_license-prod-01, var.node_license-prod-02]
  primary_az = "us-west-2a"
  secondary_az = "us-west-2b"
  ssh_public_key = var.aws_vpc_ssh_public_key_prod
}