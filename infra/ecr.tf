resource "aws_ecr_repository" "frontend" {
  name = "tienda-frontend"
}

resource "aws_ecr_repository" "backend" {
  name = "tienda-backend"
}

resource "aws_ecr_repository" "db" {
  name = "tienda-db"
}