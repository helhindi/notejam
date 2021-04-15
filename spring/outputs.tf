
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config" {
  description = "kubectl config as generated by the module."
  value       = module.eks.kubeconfig
}

output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}

output "region" {
  description = "AWS region."
  value       = var.region
}

output "private_az_subnet_ids" {
  value = module.private_subnets.az_subnet_ids
}

output "public_az_subnet_ids" {
  value = module.public_subnets.az_subnet_ids
}

output "private_az_ngw_ids" {
  value = module.private_subnets.az_ngw_ids
}

output "public_az_ngw_ids" {
  value = module.public_subnets.az_ngw_ids
}

output "private_az_route_table_ids" {
  value = module.private_subnets.az_route_table_ids
}

output "public_az_route_table_ids" {
  value = module.public_subnets.az_route_table_ids
}
