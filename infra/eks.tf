module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  iam_role_arn = "arn:aws:iam::446959396764:role/LabRole"


  create_iam_role      = false
  enable_irsa          = false
  create_kms_key       = false


  create_cloudwatch_log_group = false
}