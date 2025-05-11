output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "ID of public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  description = "List of allocation IDs of Elastic IPs created for NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}

output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = var.enable_vpc_flow_logs ? aws_flow_log.this[0].id : null
}

output "vpc_flow_log_destination" {
  description = "The ARN of the destination for VPC Flow Logs"
  value       = var.enable_vpc_flow_logs ? (var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : (var.enable_s3_logging ? aws_s3_bucket.vpc_flow_logs[0].arn : null)) : null
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}
