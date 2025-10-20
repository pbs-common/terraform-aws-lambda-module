module "lambda" {
  source = "../.."

  handler  = "bootstrap"
  filename = "../artifacts/handler.zip"
  runtime  = "provided.al2023"

  environment_vars    = {}
  layers              = []
  tracing_config_mode = "Disabled"

  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
  organization = var.organization
}
