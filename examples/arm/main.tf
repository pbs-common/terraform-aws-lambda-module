module "lambda" {
  source = "../.."

  handler  = "bootstrap"
  filename = "../artifacts/arm-handler.zip"
  runtime  = "provided.al2023"

  architectures = ["arm64"]

  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
  organization = var.organization
}
