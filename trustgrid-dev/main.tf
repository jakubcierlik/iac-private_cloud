module "trustgrid" {
  source = "../modules/trustgrid/trustgrid_ha_env"
  aws_region = var.aws_region
  customer_name = "l3av"
  env = "dev"
  certificate-ca_bundle = var.certificate-ca_bundle
  certificate-private_key = var.certificate-private_key
  certificate-ssc = var.certificate-ssc
  licenses = [var.node_license-dev-01, var.node_license-dev-02]
  primary_az = "${var.aws_region}a"
  secondary_az = "${var.aws_region}b"
  ssh_public_key = var.aws_vpc_ssh_public_key_dev
  enroll_endpoint = "https://keymaster.stage.trustgrid.io/v2/enroll"
}