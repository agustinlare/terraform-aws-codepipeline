# WebIdentity
module "service_account" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> v2.23.0"

  count         = local.create_role && var.cluster_oidc_issuer_urls != null ? 1 : 0
  create_role   = local.create_role
  role_name     = "${var.role_basename}-${var.role_name}"
  provider_urls = var.cluster_oidc_issuer_urls

  role_policy_arns = flatten([
    #    aws_iam_policy.ssm_readonly_permission.*.arn,
    #    aws_iam_policy.dynamodb_access.*.arn,
    #    aws_iam_policy.sns_access.*.arn,
    #    aws_iam_policy.sqs_write_access.*.arn,
    #    aws_iam_policy.event_bridge_write_access.*.arn,
    aws_iam_policy.ses_access.*.arn,
    aws_iam_policy.s3_buckets_readwrite_access.*.arn,
    aws_iam_policy.lambda_invoke.*.arn,
    aws_iam_policy.asg.*.arn
  ])

  tags = var.tags
}

# S3
data "aws_iam_policy_document" "s3_buckets_ro_access_document" {
  statement {
    sid       = "SAPolicyS3"
    actions   = local.ro_policy_s3
    effect    = "Allow"
    resources = local.buckets_arns
  }
}

data "aws_iam_policy_document" "s3_buckets_rw_access_document" {
  statement {
    sid       = "SAPolicyS3"
    actions   = local.rw_policy_s3
    effect    = "Allow"
    resources = local.buckets_arns
  }
}

resource "aws_iam_policy" "s3_buckets_readwrite_access" {
  count       = local.create_role && var.buckets_names != null ? 1 : 0
  name        = "s3_buckets_write_access_${var.role_name}"
  path        = "/"
  description = "S3 Buckets readwrite access for ${var.role_name}"
  policy      = var.readonly ? data.aws_iam_policy_document.s3_buckets_ro_access_document.json : data.aws_iam_policy_document.s3_buckets_rw_access_document.json

  tags = var.tags
}

# Lambda
data "aws_iam_policy_document" "lambda_invoke" {
  statement {
    sid       = "LambdaAccess"
    actions   = local.default_lambda
    effect    = "Allow"
    resources = local.lambda_arns
  }
}

resource "aws_iam_policy" "lambda_invoke" {
  count       = local.create_role && var.lambda_function != null ? 1 : 0
  name        = "lambda_invoke_${var.role_name}"
  path        = "/"
  description = "Lambda invoke ${var.role_name}"
  policy      = data.aws_iam_policy_document.lambda_invoke.json

  tags = var.tags
}

# ASG
data "aws_iam_policy_document" "asg" {
  statement {
    sid       = "AsgAccess"
    actions   = local.asg_policy
    effect    = "Allow"
    resources = local.asg_arns
  }
}

resource "aws_iam_policy" "asg" {
  count       = local.create_role && var.lambda_function != null ? 1 : 0
  name        = "asg_${var.role_name}"
  path        = "/"
  description = "ASG Policy ${var.role_name}"
  policy      = data.aws_iam_policy_document.asg.json

  tags = var.tags
}

## SES
data "aws_iam_policy_document" "ses_access_document" {
 dynamic "statement" {
   for_each = var.custom_policy_for_ses != null ? var.custom_policy_for_ses : local.default_policy_statements["ses"]

   content {
     sid       = lookup(statement.value, "sid", null)
     actions   = statement.value.actions
     resources = statement.value.resources
   }
 }
}

resource "aws_iam_policy" "ses_access" {
  count       = local.create_role && var.has_ses ? 1 : 0
  name        = "ses_full_access_${var.role_name}"
  path        = "/"
  description = "SES full access for ${var.role_name}"
  policy      = data.aws_iam_policy_document.ses_access_document.json

  tags = var.tags
}

# SSM
#data "aws_iam_policy_document" "ssm_readonly_document" {
#  statement {
#    sid = "SAPolicySSMRO"
#    actions = [
#      "ssm:GetParametersByPath",
#      "ssm:GetParameter"
#    ]
#    effect    = "Allow"
#    resources = local.ssm_arns
#  }
#  statement {
#    sid = "SAPolicyKMSRO"
#    actions = [
#      "kms:Decrypt"
#    ]
#    effect    = "Allow"
#    resources = ["*"]
#    condition {
#      test = "StringEquals"
#      values = [
#        "kms:EncryptionContext:PARAMETER_ARN"
#      ]
#      variable = format("arn:aws:ssm:%s:%s:parameter/%s*", local.region, local.account, var.role_name)
#    }
#  }
#}
#resource "aws_iam_policy" "ssm_readonly_permission" {
#  count       = local.create_role ? 1 : 0
#  name        = "ssm_read_only_${var.role_name}"
#  path        = "/"
#  description = "Parameter Store Read Only for ${var.role_name}"
#  policy      = data.aws_iam_policy_document.ssm_readonly_document.json
#}
#
#
## DynamoDB
#data "aws_iam_policy_document" "dynamodb_access_document" {
#  dynamic "statement" {
#    for_each = var.custom_policy_for_dynamo != null ? var.custom_policy_for_dynamo : local.default_policy_statements["dynamo"]
#
#    content {
#      sid       = lookup(statement.value, "sid", null)
#      actions   = statement.value.actions
#      resources = statement.value.resources
#    }
#  }
#}
#
#resource "aws_iam_policy" "dynamodb_access" {
#  count       = local.create_role && var.has_dynamo ? 1 : 0
#  name        = "dynamodb_full_access_${var.role_name}"
#  path        = "/"
#  description = "DynamoDB full access for ${var.role_name}"
#  policy      = data.aws_iam_policy_document.dynamodb_access_document.json
#}
#
## SSN
#data "aws_iam_policy_document" "sns_access_document" {
#  dynamic "statement" {
#    for_each = var.custom_policy_for_sns != null ? var.custom_policy_for_sns : local.default_policy_statements["sns"]
#
#    content {
#      sid       = lookup(statement.value, "sid", null)
#      actions   = statement.value.actions
#      resources = statement.value.resources
#    }
#  }
#}
#
#resource "aws_iam_policy" "sns_access" {
#  count       = local.create_role && var.has_sns ? 1 : 0
#  name        = "sns_access_${var.role_name}"
#  path        = "/"
#  description = "SNS access core for ${var.role_name}"
#  policy      = data.aws_iam_policy_document.sns_access_document.json
#}
#
## SQS
#data "aws_iam_policy_document" "sqs_write_access_document" {
#  statement {
#    sid       = "SAPolicySQS"
#    actions   = local.default_policy_sqs
#    effect    = "Allow"
#    resources = local.sqs_arns
#  }
#}
#
#resource "aws_iam_policy" "sqs_write_access" {
#  count       = local.create_role && var.sqs_names != null ? 1 : 0
#  name        = "sqs_write_access_${var.role_name}"
#  path        = "/"
#  description = "SQS write access for ${var.role_name}"
#  policy      = data.aws_iam_policy_document.sqs_write_access_document.json
#}
#
#
## EventBridge
#data "aws_iam_policy_document" "event_bridge_write_access_document" {
#  statement {
#    sid       = "SAPolicyEventBridge"
#    actions   = local.default_policy_eb
#    effect    = "Allow"
#    resources = local.buses_arns
#  }
#}
#
#resource "aws_iam_policy" "event_bridge_write_access" {
#  count       = local.create_role && var.event_bus_names != null ? 1 : 0
#  name        = "event_bridge_write_access_${var.role_name}"
#  path        = "/"
#  description = "EventBridge write access for ${var.role_name}"
#  policy      = data.aws_iam_policy_document.event_bridge_write_access_document.json
#}
#
