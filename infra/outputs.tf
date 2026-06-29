output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}
output "vpc_id" {
  value = module.vpc.vpc_id
}
