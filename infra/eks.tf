module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.24.0" # Fija la versión explícitamente
}