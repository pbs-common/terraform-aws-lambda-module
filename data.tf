data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "vpc" {
  count = var.add_vpc_config && var.vpc_id == null ? 1 : 0
  tags = {
    "Name" : "*${var.environment}*"
  }
}

data "aws_subnets" "private_subnets" {
  count = var.add_vpc_config && var.subnets == null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*-private-*"]
  }
}

// Public SSM parameters for latest lambda extension versions
data "aws_ssm_parameter" "parameters_and_secrets_x86_latest_version" {
  name = "/aws/service/aws-parameters-and-secrets-lambda-extension/x86/latest"
}

data "aws_ssm_parameter" "parameters_and_secrets_arm_latest_version" {
  name = "/aws/service/aws-parameters-and-secrets-lambda-extension/arm64/latest"
}

data "aws_ssm_parameter" "app_config_x86_latest_version" {
  name = "/aws/service/aws-appconfig/lambda-extension/x86/latest"
}

data "aws_ssm_parameter" "app_config_arm_latest_version" {
  name = "/aws/service/aws-appconfig/lambda-extension/arm64/latest"
}
