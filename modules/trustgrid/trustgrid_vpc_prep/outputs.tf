output "trustgrid_instance_profile_name" {
    value = aws_iam_instance_profile.trustgrid_instance_profile.name
}

output "trustgrid_log_group" {
    value = aws_cloudwatch_log_group.trustgrid_logs.name
}

output "syslog_log_group" {
    value = aws_cloudwatch_log_group.syslog.name
}