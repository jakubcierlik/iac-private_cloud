locals {
  tags = {
    "environment" : var.env,
    "vendor" : "trustgrid"
  }
  prefix = "${var.customer_name}-${local.tags["environment"]}-trustgrid"
}

# ------------------------------------------------ Application EC2/VPC ------------------------------------------------

module "vpc_setup" {
  source        = "../vpc_setup"
  aws_region    = "us-west-2"
  customer_name = local.prefix
  primary_az    = "us-west-2a"
  secondary_az  = "us-west-2b"
  public_key    = var.ssh_public_key
  tags          = local.tags
}

module "trustgrid_vpc_prep" {
  source           = "../trustgrid_vpc_prep"
  environment_name = local.prefix
  route_table_arn  = module.vpc_setup.private-rt-arn
  tags             = local.tags
}

module "primary_node" {
  data_security_group_ids       = [module.vpc_setup.security_group_id-vpc_default]
  data_subnet_id                = module.vpc_setup.private_subnet_01_id
  enroll_endpoint               = var.enroll_endpoint
  instance_profile_name         = module.trustgrid_vpc_prep.trustgrid_instance_profile_name
  instance_type                 = "t3.medium"
  is_appgateway                 = true
  is_tggateway                  = true
  is_wggateway                  = true
  mgmt_sg_id                    = module.vpc_setup.security_group_id-mgmt
  data_sg_id                    = module.vpc_setup.security_group_id-data
  key_pair_name                 = module.vpc_setup.key_name
  license                       = var.licenses[0]
  management_security_group_ids = [module.vpc_setup.security_group_id-vpc_default]
  management_subnet_id          = module.vpc_setup.public_subnet_01_id
  name                          = "${local.prefix}-gateway-01"
  source                        = "../trustgrid_single_node"
  syslog_log_group_name         = module.trustgrid_vpc_prep.syslog_log_group
  tags                          = local.tags
  trustgrid_log_group_name      = module.trustgrid_vpc_prep.trustgrid_log_group
}

module "secondary_node" {
  data_security_group_ids       = [module.vpc_setup.security_group_id-vpc_default]
  data_subnet_id                = module.vpc_setup.private_subnet_02_id
  enroll_endpoint               = var.enroll_endpoint
  instance_profile_name         = module.trustgrid_vpc_prep.trustgrid_instance_profile_name
  instance_type                 = "t3.medium"
  is_appgateway                 = true
  is_tggateway                  = true
  is_wggateway                  = true
  mgmt_sg_id                    = module.vpc_setup.security_group_id-mgmt
  data_sg_id                    = module.vpc_setup.security_group_id-data
  key_pair_name                 = module.vpc_setup.key_name
  license                       = var.licenses[1]
  management_security_group_ids = [module.vpc_setup.security_group_id-vpc_default]
  management_subnet_id          = module.vpc_setup.public_subnet_02_id
  name                          = "${local.prefix}-gateway-02"
  source                        = "../trustgrid_single_node"
  syslog_log_group_name         = module.trustgrid_vpc_prep.syslog_log_group
  tags                          = local.tags
  trustgrid_log_group_name      = module.trustgrid_vpc_prep.trustgrid_log_group
}

# ----------------------------------- Network load balancer for Trustgrid wireguard  -----------------------------------

resource "aws_lb_target_group" "wireguard" {
  name     = "${local.prefix}-tg-wireguard"
  port     = 51820
  vpc_id   = module.vpc_setup.vpc_id
  protocol = "UDP"
  tags     = local.tags

  health_check {
    interval = 10
    path     = "/status"
    port     = "9001"
  }
}

resource "aws_lb_target_group_attachment" "wireguard_primary_node" {
  target_group_arn = aws_lb_target_group.wireguard.arn
  target_id        = module.primary_node.node_instance_id
}

resource "aws_lb_target_group_attachment" "wireguard_secondary_node" {
  target_group_arn = aws_lb_target_group.wireguard.arn
  target_id        = module.secondary_node.node_instance_id
}

resource "aws_lb" "wireguard" {
  name               = "${local.prefix}-lb-wireguard"
  load_balancer_type = "network"
  tags               = local.tags
  subnets            = [
    module.vpc_setup.public_subnet_01_id,
    module.vpc_setup.public_subnet_02_id
  ]
}

resource "aws_lb_listener" "wireguard" {
  load_balancer_arn = aws_lb.wireguard.arn
  port              = "51820"
  protocol          = "UDP"
  tags              = local.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wireguard.arn
  }
}

# -------------------------------- Application load balancer for Trustgrid application --------------------------------

resource "aws_lb_target_group" "app" {
  name     = "${local.prefix}-tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc_setup.vpc_id
  tags     = local.tags

  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_target_group_attachment" "app_primary_node" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = module.primary_node.node_instance_id
}

resource "aws_lb_target_group_attachment" "app_secondary_node" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = module.secondary_node.node_instance_id
}

resource "aws_lb" "app" {
  name                             = "${local.prefix}-lb-app"
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = true
  security_groups                  = [module.vpc_setup.security_group_id-vpc_default]
  tags                             = local.tags

  subnets = [
    module.vpc_setup.public_subnet_01_id,
    module.vpc_setup.public_subnet_02_id
  ]
}

resource "aws_acm_certificate" "app_lb" {
  private_key       = var.certificate-private_key
  certificate_body  = var.certificate-ssc
  certificate_chain = var.certificate-ca_bundle
  tags              = local.tags
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.app_lb.arn
  tags              = local.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}