output "key_name" {
    value = aws_key_pair.cust_key_pair.key_name
}

output "vpc_id" {
    value = aws_vpc.main.id
}

output "primary_az" {
    value = aws_subnet.private_01.availability_zone
}

output "secondary_az" {
    value = aws_subnet.private_01.availability_zone
}

output "public_subnet_01_id" {
    value = aws_subnet.public_01.id
}

output "private_subnet_01_id" {
    value = aws_subnet.private_01.id
}

output "public_subnet_02_id" {
    value = aws_subnet.public_02.id
}

output "private_subnet_02_id" {
    value = aws_subnet.private_02.id
}

output "igw" {
    value = aws_internet_gateway.main.id
}

output "public-rt-id" {
    value = aws_route_table.public.id
}

output "private-rt-id" {
    value = aws_route_table.private.id
}

output "public-rt-arn" {
    value = aws_route_table.public.arn
}

output "private-rt-arn" {
    value = aws_route_table.private.arn
}

output "security_group_id-vpc_default" {
    value = aws_default_security_group.default.id
}

output "security_group_id-mgmt" {
    value = aws_security_group.gateway_mgmt.id
}

output "security_group_id-data" {
    value = aws_security_group.gateway_data.id
}