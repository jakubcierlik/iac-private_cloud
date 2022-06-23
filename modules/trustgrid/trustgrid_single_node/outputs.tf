output "node_instance_id" {
    value = aws_instance.trustgrid_node.id
}

output "node_instance_ami_id" {
    value = aws_instance.trustgrid_node.ami
}

output "node_mgmt_public_ip" {
    value = aws_eip.mgmt.public_ip
}

output "node_mgmt_private_ip" {
    value = aws_network_interface.mgmt.private_ips
}

output "node_data_private_ip" {
    value = aws_network_interface.data.private_ips
}