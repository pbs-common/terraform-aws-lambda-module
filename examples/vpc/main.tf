module "lambda" {
  source = "../.."

  handler  = "bootstrap"
  filename = "../artifacts/handler.zip"
  runtime  = "provided.al2023"

  add_vpc_config = true

  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
  organization = var.organization
}
