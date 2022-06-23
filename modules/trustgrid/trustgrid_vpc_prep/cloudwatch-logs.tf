resource "aws_cloudwatch_log_group" "trustgrid_logs" {
  name = "${var.environment_name}-/var/log/trustgrid"
}

resource "aws_cloudwatch_log_group" "syslog" {
  name = "${var.environment_name}-/var/log/syslog"
}