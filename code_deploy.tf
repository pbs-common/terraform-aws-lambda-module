resource "aws_iam_role" "code_deploy" {
  count = var.code_deploy == null ? 0 : 1

  name = "${local.name}-deployment-group-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "codedeploy.amazonaws.com"
          },
          "Effect" : "Allow",
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "codedeploy_deployment_group_sample" {
  count      = var.code_deploy == null ? 0 : 1
  role       = aws_iam_role.code_deploy[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambdaLimited"
}

resource "aws_codedeploy_app" "this" {
  count            = var.code_deploy == null ? 0 : 1
  compute_platform = "Lambda"
  name             = local.name
}

resource "aws_codedeploy_deployment_group" "this" {
  count                 = var.code_deploy == null ? 0 : 1
  app_name              = aws_codedeploy_app.this[0].name
  deployment_group_name = "${local.name}-deployment-group"
  service_role_arn      = aws_iam_role.code_deploy[0].arn

  deployment_config_name = var.code_deploy.deployment_config_name

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = var.code_deploy.alarm_arns
    enabled = true
  }
}

// The current version that's live
resource "aws_lambda_alias" "live" {
  count            = var.code_deploy == null ? 0 : 1
  name             = "LIVE"
  function_name    = aws_lambda_function.lambda.function_name
  function_version = "1"
}
