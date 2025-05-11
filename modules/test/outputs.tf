output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

output "nat_public_ips" {
  description = "List of public IPs of NAT Gateways"
  value       = module.vpc.nat_public_ips
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_data" {
  description = "The base64 encoded certificate data for the cluster"
  value       = module.eks.cluster_ca_data
}
