output "arn" {
  description = "ARN of the lambda function"
  value       = aws_lambda_function.lambda.arn
}

output "name" {
  description = "Name of the lambda function"
  value       = aws_lambda_function.lambda.function_name
}

output "invoke_arn" {
  description = "Invocation ARN of the lambda function"
  value       = aws_lambda_function.lambda.invoke_arn
}

output "qualified_arn" {
  description = "Qualified ARN of the lambda function"
  value       = aws_lambda_function.lambda.qualified_arn
}

output "sg" {
  description = "Security group of the lambda function if there is one"
  value       = local.security_group_id
}

output "code_deploy_app_name" {
  description = "The name of the CodeDeploy application associated with this lambda, if there is one"
  value       = var.code_deploy == null ? null : aws_codedeploy_app.this[0].name
}

output "code_deploy_deployment_group_name" {
  description = "The name of the CodeDeploy deployment group created for this lambda, if there is one"
  value       = var.code_deploy == null ? null : aws_codedeploy_deployment_group.this[0].deployment_group_name
}

output "code_deploy_revision" {
  description = "Revision JSON needed to start a CodeDeploy deployment to rollout a new revision"
  value = var.code_deploy == null ? null : jsonencode({
    revisionType = "AppSpecContent"
    appSpecContent = {
      content = {
        version = "0.0"
        Resources = [
          {
            "${aws_lambda_function.lambda.function_name}" = {
              Type = "AWS::Lambda::Function"
              Properties = {
                Name           = aws_lambda_function.lambda.function_name
                Alias          = "LIVE"
                CurrentVersion = data.aws_lambda_alias.live[0].function_version
                TargetVersion  = data.aws_lambda_alias.live[0].function_version // TODO: point to the NEXT alias
              }
            }
          }
        ]
      }
    }
  })
}