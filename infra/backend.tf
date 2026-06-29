terraform {
  backend "s3" {
    bucket = "tienda-terraform-state"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
