locals {
  # This is the default SSM path for Lambdas created like this.
  ssm_path = "/${var.environment}/${var.product}/"
}

resource "aws_ssm_parameter" "name" {
  name  = "${local.ssm_path}name"
  type  = "SecureString"
  value = "John"
}

module "lambda" {
  source = "../.."

  handler  = "bootstrap"
  filename = "../artifacts/handler.zip"
  runtime  = "provided.al2023"

  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
  organization = var.organization
}
