module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  iam_role_arn = "arn:aws:iam::446959396764:role/LabRole"
}