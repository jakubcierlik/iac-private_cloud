terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

data "aws_ami" "trustgrid_node" {
  owners      = ["079972220921"]
  most_recent = true
  filter {
    name   = "name"
    values = ["trustgrid-agent*"]
  }
}

data "aws_iam_instance_profile" "instance_profile" {
  name = var.instance_profile_name
}

data "aws_region" "current" {}

data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    filename     = "bootstrap.cfg"
    content      = templatefile("${path.module}/templates/cloud-init.yaml.tpl",
      {
        license                   = var.license,
        trustgrid_log_group_name  = var.trustgrid_log_group_name,
        trustgrid_log_stream_name = aws_cloudwatch_log_stream.trustgrid_logs.name,
        syslog_log_group_name     = var.syslog_log_group_name,
        syslog_log_stream_name    = aws_cloudwatch_log_stream.syslog.name
      })
  }

  part {
    content_type = "text/x-shellscript"
    filename     = "bootstrap.sh"
    content      = templatefile("${path.module}/scripts/bootstrap.sh.tpl",
      {
        region          = data.aws_region.current.name,
        enroll_endpoint = var.enroll_endpoint
      })
  }
}

resource "aws_cloudwatch_log_stream" "trustgrid_logs" {
  name           = var.name
  log_group_name = var.trustgrid_log_group_name
}

resource "aws_cloudwatch_log_stream" "syslog" {
  name           = var.name
  log_group_name = var.syslog_log_group_name
}

data "aws_iam_policy_document" "log_streams" {
  statement {
    actions   = ["logs:DescribeLogStreams"]
    resources = ["*"]
  }

  statement {
    actions   = ["logs:PutLogEvents"]
    resources = [
      "${aws_cloudwatch_log_stream.trustgrid_logs.arn}:*",
      aws_cloudwatch_log_stream.trustgrid_logs.arn
    ]
  }

  statement {
    actions   = ["logs:PutLogEvents"]
    resources = [
      "${aws_cloudwatch_log_stream.syslog.arn}:*",
      aws_cloudwatch_log_stream.syslog.arn
    ]
  }
}

resource "aws_iam_role_policy" "node_logs" {
  name_prefix = "${var.name}-trustgrid-log-policy"
  policy      = data.aws_iam_policy_document.log_streams.json
  role        = data.aws_iam_instance_profile.instance_profile.role_name
}

data "aws_subnet" "mgmt" {
  id = var.management_subnet_id
}

resource "aws_network_interface" "mgmt" {
  description = "Management"
  subnet_id         = var.management_subnet_id
  security_groups   = [var.mgmt_sg_id]
  source_dest_check = false
  tags              = merge(var.tags, { Name = "${var.name}-mgmt-nic" })
}

resource "aws_network_interface" "data" {
  description = "Data"
  subnet_id         = var.data_subnet_id
  security_groups   = [var.data_sg_id]
  #  private_ips       = [var.data_ip]
  source_dest_check = false
  tags              = merge(var.tags, { Name = "${var.name}-data-nic" })
}

resource "aws_eip" "mgmt" {
  vpc               = true
  network_interface = aws_network_interface.mgmt.id
  tags              = merge(var.tags, { Name = "${var.name}-mgmt-ip" })
}

resource "aws_instance" "trustgrid_node" {
  ami           = data.aws_ami.trustgrid_node.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  user_data            = data.template_cloudinit_config.cloud_init.rendered
  iam_instance_profile = data.aws_iam_instance_profile.instance_profile.name

  network_interface {
    network_interface_id = aws_network_interface.mgmt.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.data.id
    device_index         = 1
  }

  tags = merge(var.tags, { Name = var.name })

  root_block_device {
    encrypted   = var.root_block_device_encrypt
    volume_size = var.root_block_device_size
  }

  lifecycle {
    ignore_changes = all
  }
}
