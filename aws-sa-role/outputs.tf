#
output "service_account_role_arn" {
  value = element(concat(module.service_account.*.this_iam_role_arn, [""]), 0)
}

#
output "service_account_role_name" {
  value = element(concat(module.service_account.*.this_iam_role_name, [""]), 0)
}

output "s3_buckets_readwrite_access_arn" {
  value = element(concat(aws_iam_policy.s3_buckets_readwrite_access.*.arn, [""]), 0)
}

output "s3_buckets_readwrite_access_id" {
  value = element(concat(aws_iam_policy.s3_buckets_readwrite_access.*.id, [""]), 0)
}

output "ses_policy_arn" {
  value = element(concat(aws_iam_policy.ses_access.*.arn, [""]), 0)
}

output "ses_policy_id" {
  value = element(concat(aws_iam_policy.ses_access.*.id, [""]), 0)
}

output "lambda_policy_arn" {
  value = element(concat(aws_iam_policy.lambda_invoke.*.arn, [""]), 0)
}

output "lambda_policy_id" {
  value = element(concat(aws_iam_policy.lambda_invoke.*.id, [""]), 0)
}

#
#output "ssm_readonly_permission_arn" {
#  value = element(concat(aws_iam_policy.ssm_readonly_permission.*.arn, [""]), 0)
#}
#
##
#output "ssm_readonly_permission_id" {
#  value = element(concat(aws_iam_policy.ssm_readonly_permission.*.id, [""]), 0)
#}
#
##
#output "dynamodb_access_arn" {
#  value = element(concat(aws_iam_policy.dynamodb_access.*.arn, [""]), 0)
#}
#
##
#output "dynamodb_access_id" {
#  value = element(concat(aws_iam_policy.dynamodb_access.*.id, [""]), 0)
#}
#
##
#output "sns_access_arn" {
#  value = element(concat(aws_iam_policy.sns_access.*.arn, [""]), 0)
#}
#
##
#output "sns_access_id" {
#  value = element(concat(aws_iam_policy.sns_access.*.id, [""]), 0)
#}
#
##
#output "sqs_write_access_arn" {
#  value = element(concat(aws_iam_policy.sqs_write_access.*.arn, [""]), 0)
#}
#
##
#output "sqs_write_access_id" {
#  value = element(concat(aws_iam_policy.sqs_write_access.*.id, [""]), 0)
#}
#
##
#output "ses_access_arn" {
#  value = element(concat(aws_iam_policy.ses_access.*.arn, [""]), 0)
#}
#
##
#output "ses_access_id" {
#  value = element(concat(aws_iam_policy.ses_access.*.id, [""]), 0)
#}
#
##
#output "event_bridge_write_access_arn" {
#  value = element(concat(aws_iam_policy.event_bridge_write_access.*.arn, [""]), 0)
#}
#
##
#output "event_bridge_write_access_id" {
#  value = element(concat(aws_iam_policy.event_bridge_write_access.*.id, [""]), 0)
#}

#
