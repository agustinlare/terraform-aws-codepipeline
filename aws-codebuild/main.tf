data "aws_caller_identity" "default" {
}

data "aws_region" "default" {
}

# resource "aws_iam_role" "default" {
#   count                 = module.this.enabled ? 1 : 0
#   name                  = module.this.id
#   assume_role_policy    = data.aws_iam_policy_document.role.json
#   force_detach_policies = true
#   tags                  = module.this.tags
# }

# data "aws_iam_policy_document" "role" {
#   statement {
#     sid = ""

#     actions = [
#       "sts:AssumeRole",
#     ]

#     principals {
#       type        = "Service"
#       identifiers = ["codebuild.amazonaws.com"]
#     }

#     effect = "Allow"
#   }
# }

# resource "aws_iam_policy" "default" {
#   count  = module.this.enabled ? 1 : 0
#   name   = module.this.id
#   path   = "/service-role/"
#   policy = data.aws_iam_policy_document.combined_permissions.json
# }

# resource "aws_iam_policy" "default_cache_bucket" {
#   count = module.this.enabled && local.s3_cache_enabled ? 1 : 0


#   name   = "${module.this.id}-cache-bucket"
#   path   = "/service-role/"
#   policy = join("", data.aws_iam_policy_document.permissions_cache_bucket.*.json)
# }

# data "aws_iam_policy_document" "permissions" {
#   statement {
#     sid = ""

#     actions = compact(concat([
#       "codecommit:GitPull",
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:CompleteLayerUpload",
#       "ecr:GetAuthorizationToken",
#       "ecr:InitiateLayerUpload",
#       "ecr:PutImage",
#       "ecr:UploadLayerPart",
#       "ecs:RunTask",
#       "iam:PassRole",
#       "logs:CreateLogGroup",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "ssm:GetParameters",
#       "secretsmanager:GetSecretValue",
#     ], var.extra_permissions))

#     effect = "Allow"

#     resources = [
#       "*",
#     ]
#   }
# }

# data "aws_iam_policy_document" "vpc_permissions" {
#   count = module.this.enabled && var.vpc_config != {} ? 1 : 0

#   statement {
#     sid = ""

#     actions = [
#       "ec2:CreateNetworkInterface",
#       "ec2:DescribeDhcpOptions",
#       "ec2:DescribeNetworkInterfaces",
#       "ec2:DeleteNetworkInterface",
#       "ec2:DescribeSubnets",
#       "ec2:DescribeSecurityGroups",
#       "ec2:DescribeVpcs"
#     ]

#     resources = [
#       "*",
#     ]
#   }

#   statement {
#     sid = ""

#     actions = [
#       "ec2:CreateNetworkInterfacePermission"
#     ]

#     resources = [
#       "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:network-interface/*"
#     ]

#     condition {
#       test     = "StringEquals"
#       variable = "ec2:Subnet"
#       values = formatlist(
#         "arn:aws:ec2:${var.aws_region}:${var.aws_account_id}:subnet/%s",
#         var.vpc_config.subnets
#       )
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "ec2:AuthorizedService"
#       values = [
#         "codebuild.amazonaws.com"
#       ]
#     }

#   }
# }

# data "aws_iam_policy_document" "combined_permissions" {
#   override_policy_documents = compact([
#     data.aws_iam_policy_document.permissions.json,
#     var.vpc_config != {} ? join("", data.aws_iam_policy_document.vpc_permissions.*.json) : null
#   ])
# }

# data "aws_iam_policy_document" "permissions_cache_bucket" {
#   count = module.this.enabled && local.s3_cache_enabled ? 1 : 0
#   statement {
#     sid = ""

#     actions = [
#       "s3:*",
#     ]

#     effect = "Allow"

#     resources = [
#       join("", aws_s3_bucket.cache_bucket.*.arn),
#       "${join("", aws_s3_bucket.cache_bucket.*.arn)}/*",
#     ]
#   }
# }

# resource "aws_iam_role_policy_attachment" "default" {
#   count      = module.this.enabled ? 1 : 0
#   policy_arn = join("", aws_iam_policy.default.*.arn)
#   role       = join("", aws_iam_role.default.*.id)
# }

# resource "aws_iam_role_policy_attachment" "default_cache_bucket" {
#   count      = module.this.enabled && local.s3_cache_enabled ? 1 : 0
#   policy_arn = join("", aws_iam_policy.default_cache_bucket.*.arn)
#   role       = join("", aws_iam_role.default.*.id)
# }

data "aws_iam_role" "codepipeline" {
  # Este es el nombre del role global que tiene permisos
  name = "codebuild-service-role-${module.this.stage}"
}

resource "aws_codebuild_source_credential" "authorization" {
  count       = module.this.enabled && var.private_repository ? 1 : 0
  auth_type   = var.source_credential_auth_type
  server_type = var.source_credential_server_type
  token       = var.source_credential_token
  user_name   = var.source_credential_user_name
}

resource "aws_codebuild_project" "default" {
  count          = module.this.enabled ? 1 : 0
  name           = module.this.id
  service_role   = data.aws_iam_role.codepipeline.arn
  badge_enabled  = var.badge_enabled
  build_timeout  = var.build_timeout
  source_version = var.source_version != "" ? var.source_version : null
  tags = {
    for name, value in module.this.tags :
    name => value
    if length(value) > 0
  }

  artifacts {
    type     = var.artifact_type
    location = var.artifact_location
  }

  cache {
    type     = "S3"
    location = format("%s/%s", var.cache_bucket_name, "cache")
  }

  environment {
    compute_type    = var.build_compute_type
    image           = var.build_image
    type            = var.build_type
    privileged_mode = var.privileged_mode

    environment_variable {
      name  = "AWS_REGION"
      value = signum(length(var.aws_region)) == 1 ? var.aws_region : data.aws_region.default.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = signum(length(var.aws_account_id)) == 1 ? var.aws_account_id : data.aws_caller_identity.default.account_id
    }

    dynamic "environment_variable" {
      for_each = signum(length(var.image_repo_name)) == 1 ? [""] : []
      content {
        name  = "IMAGE_REPO_NAME"
        value = var.image_repo_name
      }
    }

    dynamic "environment_variable" {
      for_each = signum(length(var.image_tag)) == 1 ? [""] : []
      content {
        name  = "IMAGE_TAG"
        value = var.image_tag
      }
    }

    dynamic "environment_variable" {
      for_each = signum(length(module.this.stage)) == 1 ? [""] : []
      content {
        name  = "STAGE"
        value = module.this.stage
      }
    }

    dynamic "environment_variable" {
      for_each = signum(length(var.github_token)) == 1 ? [""] : []
      content {
        name  = "GITHUB_TOKEN"
        value = var.github_token
      }
    }

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }

  }

  source {
    buildspec           = var.buildspec
    type                = var.source_type
    location            = var.source_location
    report_build_status = var.report_build_status
    git_clone_depth     = var.git_clone_depth != null ? var.git_clone_depth : null

    dynamic "auth" {
      for_each = var.private_repository ? [""] : []
      content {
        type     = "OAUTH"
        resource = join("", aws_codebuild_source_credential.authorization.*.id)
      }
    }

    dynamic "git_submodules_config" {
      for_each = var.fetch_git_submodules ? [""] : []
      content {
        fetch_submodules = true
      }
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_config) > 0 ? [""] : []
    content {
      vpc_id             = lookup(var.vpc_config, "vpc_id", null)
      subnets            = lookup(var.vpc_config, "subnets", null)
      security_group_ids = lookup(var.vpc_config, "security_group_ids", null)
    }
  }

  dynamic "logs_config" {
    for_each = length(var.logs_config) > 0 ? [""] : []
    content {
      dynamic "cloudwatch_logs" {
        for_each = contains(keys(var.logs_config), "cloudwatch_logs") ? { key = var.logs_config["cloudwatch_logs"] } : {}
        content {
          status      = lookup(cloudwatch_logs.value, "status", null)
          group_name  = lookup(cloudwatch_logs.value, "group_name", null)
          stream_name = lookup(cloudwatch_logs.value, "stream_name", null)
        }
      }

      dynamic "s3_logs" {
        for_each = contains(keys(var.logs_config), "s3_logs") ? { key = var.logs_config["s3_logs"] } : {}
        content {
          status              = lookup(s3_logs.value, "status", null)
          location            = lookup(s3_logs.value, "location", null)
          encryption_disabled = lookup(s3_logs.value, "encryption_disabled", null)
        }
      }
    }
  }
}
