locals {
  create_role  = var.role_name != null && var.environment != null
  account      = coalesce(var.account_id, data.aws_caller_identity.current.account_id)
  region       = coalesce(var.aws_region, data.aws_region.current.name)
  buckets_arns = var.buckets_names != null ? concat(formatlist("arn:aws:s3:::%s/*", var.buckets_names), formatlist("arn:aws:s3:::%s", var.buckets_names)) : []
  lambda_arns = var.lambda_function != null ? formatlist("arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:%s", var.lambda_function) : []
  asg_arns = var.asg != null ? formatlist("arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/%s", var.asg) : []

  default_policy_s3 = [
    "s3:PutObject",
    "s3:GetObject",
    "s3:DeleteObject",
    "s3:ListBucket",
    "s3:PutObjectAcl"
  ]

  default_lambda = [
    "lambda:InvokeFunction"
  ]
  
  asg_policy = [
    "autoscaling:UpdateAutoScalingGroup"
  ]

  rw_policy_s3 = [
    "s3:GetBucketVersioning",
    "s3:ListBucketVersions",
    "s3:ListBucket",
    "s3:*Object*"
  ]

  ro_policy_s3 = [
    "s3:ListBucketVersions",
    "s3:GetBucketVersioning",
    "s3:GetObject",
    "s3:GetObjectAttributes",
    "s3:GetObjectTagging",
    "s3:GetObjectVersion",
    "s3:ListBucket"
  ]

  policy_ses = [
    "ses:SendEmail",
    "ses:SendTemplatedEmail",
    "ses:SendRawEmail",
    "ses:SendBulkTemplatedEmail",
    "ses:SendCustomVerificationEmail"
  ]

  default_policy_dynamo = [
    "dynamodb:BatchGetItem",
    "dynamodb:BatchWriteItem",
    "dynamodb:ConditionCheckItem",
    "dynamodb:DeleteItem",
    "dynamodb:DescribeTable",
    "dynamodb:GetItem",
    "dynamodb:ListTagsOfResource",
    "dynamodb:PutItem",
    "dynamodb:Query",
    "dynamodb:Scan",
    "dynamodb:TagResource",
    "dynamodb:UntagResource",
    "dynamodb:UpdateItem",
    "dynamodb:UpdateTable"
  ]

  default_policy_sns = [
    "sns:Subscribe",
    "sns:Publish"
  ]

  default_policy_sqs = [
    "sqs:SendMessage",
    "sqs:DeleteMessage",
    "sqs:SendMessageBatch",
    "sqs:ReceiveMessage"
  ]

  default_policy_eb = [
    "events:PutEvents"
  ]

  default_policy_statements = {
    dynamo = [{ sid = "SAPolicyDynamo", actions = local.default_policy_dynamo, resources = [
      format("arn:aws:dynamodb:*:%s:table/*", local.account)
    ] }]
    ses = [{ sid = "SAPolicySES", actions = local.policy_ses, resources = [
      "*"]
    }]
    sns = [{ sid = "SAPolicySNS", actions = local.default_policy_sns, resources = [
      format("arn:aws:sns:%s:%s:auth-otp-updates-topic", local.region, local.account)
    ] }]
  }
}