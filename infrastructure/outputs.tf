output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway Elastic IP"
  value       = aws_eip.nat.public_ip
}

output "public_route_table_id" {
  description = "Public Route Table ID"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Private Route Table ID"
  value       = aws_route_table.private.id
}

output "web_server_instance_id" {
  description = "Web Server Instance ID"
  value       = aws_instance.web_server.id
}

output "web_server_public_ip" {
  description = "Web Server Public IP"
  value       = aws_eip.web_server_eip.public_ip
}

output "web_server_private_ip" {
  description = "Web Server Private IP"
  value       = aws_instance.web_server.private_ip
}

output "web_server_ssh_command" {
  description = "SSH command to connect to web server"
  value       = "ssh -i durga-windows.pem ec2-user@${aws_eip.web_server_eip.public_ip}"
}

output "web_security_group_id" {
  description = "Web Security Group ID"
  value       = aws_security_group.web_sg.id
}

output "db_server_instance_id" {
  description = "Database Server Instance ID"
  value       = aws_instance.db_server.id
}

output "db_server_private_ip" {
  description = "Database Server Private IP"
  value       = aws_instance.db_server.private_ip
}

output "db_server_ssh_command_from_web" {
  description = "SSH command to connect to database server from web server"
  value       = "ssh -i durga-windows.pem ec2-user@${aws_instance.db_server.private_ip}"
}

output "db_security_group_id" {
  description = "Database Security Group ID"
  value       = aws_security_group.db_sg.id
}

output "ec2_iam_role_name" {
  description = "EC2 IAM Role Name"
  value       = aws_iam_role.ec2_role.name
}

output "web_server_url" {
  description = "Web Server URL"
  value       = "http://${aws_eip.web_server_eip.public_ip}"
}
