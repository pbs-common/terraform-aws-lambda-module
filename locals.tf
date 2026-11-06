locals {
  name = var.name != null ? var.name : var.product

  source_code_hash = try(filebase64sha256(var.filename), null)

  ssm_path         = var.ssm_path != null ? var.ssm_path : "/${var.environment}/${local.name}"
  environment_vars = var.environment_vars != null ? var.environment_vars : { "SSM_PATH" = local.ssm_path }
  environment_map  = length(local.environment_vars) == 0 ? toset([]) : toset([local.environment_vars])

  // Lambda insights doesn't publish an SSM parameter with the latest version,
  // so we have to rely on the table here:
  // https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-extension-versions.html
  lambda_insights_extension_version = var.lambda_insights_extension_version != null ? var.lambda_insights_extension_version : var.architectures == tolist(["arm64"]) ? "31" : "66"
  lambda_insights_extension_name    = var.architectures == tolist(["arm64"]) ? "LambdaInsightsExtension-Arm64" : "LambdaInsightsExtension"

  // Pulled dynamically from SSM. Note that the parameter value is the layer ARN, and not just the version
  parameters_and_secrets_extension_arn = var.architectures == tolist(["arm64"]) ? data.aws_ssm_parameter.parameters_and_secrets_arm_latest_version.value : data.aws_ssm_parameter.parameters_and_secrets_x86_latest_version.value

  app_config_extension_arn = var.architectures == tolist(["arm64"]) ? data.aws_ssm_parameter.app_config_arm_latest_version.value : data.aws_ssm_parameter.app_config_x86_latest_version.value

  # Layers aren't supported for Docker images.
  default_layers = var.image_uri != null ? [] : compact([
    "arn:aws:lambda:${data.aws_region.current.region}:${var.lambda_insights_extension_account_number}:layer:${local.lambda_insights_extension_name}:${local.lambda_insights_extension_version}",
    var.add_ssm_extension_layer ? local.parameters_and_secrets_extension_arn : "",
    var.add_app_config_extension_layer ? local.app_config_extension_arn : "",
  ])

  layers                = var.layers != null ? var.layers : local.default_layers
  description           = var.description != null ? var.description : "${local.name} function"
  policy_json           = var.policy_json != null ? var.policy_json : data.aws_iam_policy_document.default_policy_document[0].json
  role                  = var.role_arn != null ? var.role_arn : module.default_role[0].arn
  vpc_id                = var.vpc_id != null ? var.vpc_id : var.add_vpc_config ? data.aws_vpc.vpc[0].id : null
  create_security_group = var.add_vpc_config && var.security_group_id == null
  subnet_ids            = var.subnets != null ? var.subnets : var.add_vpc_config ? flatten([for subnet in data.aws_subnets.private_subnets : subnet.ids]) : []
  security_group_id     = local.create_security_group ? aws_security_group.sg[0].id : var.security_group_id
  log_group_name        = "/aws/lambda/${local.name}"

  creator = "terraform"

  defaulted_tags = merge(
    var.tags,
    {
      Name                                      = local.name
      "${var.organization}:billing:product"     = var.product
      "${var.organization}:billing:owner"       = var.owner
      "${var.organization}:billing:environment" = var.environment
      creator                                   = local.creator
      repo                                      = var.repo
    }
  )

  tags = merge({ for k, v in local.defaulted_tags : k => v if lookup(data.aws_default_tags.common_tags.tags, k, "") != v })
}

data "aws_default_tags" "common_tags" {}
