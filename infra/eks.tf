resource "aws_eks_cluster" "main" {
  name     = "tienda-cluster"
  role_arn = "arn:aws:iam::446959396764:role/LabRole"

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "nodes"
  node_role_arn   = "arn:aws:iam::446959396764:role/LabRole"

  subnet_ids = module.vpc.private_subnets

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  depends_on = [aws_eks_cluster.main]
}
