module "lambda" {
  source = "../.."

  handler  = "bootstrap"
  filename = "../artifacts/handler.zip"
  runtime  = "provided.al2023"

  layers = [
    "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:21",
    "arn:aws:lambda:us-east-1:177933569100:layer:AWS-Parameters-and-Secrets-Lambda-Extension:2",
  ]

  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo
  organization = var.organization
}
