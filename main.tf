data "aws_caller_identity" "default" {
}

data "aws_region" "default" {
}

locals {
  enabled         = module.this.enabled
  webhook_enabled = local.enabled && var.webhook_enabled ? true : false
  webhook_count   = local.webhook_enabled ? 1 : 0
  webhook_secret  = join("", random_password.webhook_secret.*.result)
  webhook_url     = join("", aws_codepipeline_webhook.default.*.url)
}

resource "aws_ecr_repository" "default" {
  name                 = "${module.this.name}-${module.this.stage}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Terraform   = true
    Environment = module.this.stage
  }
}

resource "aws_s3_bucket" "default" {
  bucket        = module.this.id
  force_destroy = var.force_destroy
  tags          = module.this.tags

  lifecycle {
    ignore_changes = [server_side_encryption_configuration, lifecycle_rule, ]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "default_cache_lifecycle" {
  bucket = aws_s3_bucket.default.id

  rule {
    id = "codebuildcache"
    expiration {
      days = var.cache_expiration_days
    }

    filter {
      prefix = "cache/"
    }
    status = "Enabled"
  }

  depends_on = [
    aws_s3_bucket.default
  ]
}

resource "aws_s3_bucket_logging" "default_loggin" {
  count = var.access_log_bucket_name != "" ? 1 : 0

  bucket        = aws_s3_bucket.default.id
  target_bucket = var.access_log_bucket_name
  target_prefix = "logs/${module.this.id}/"

  depends_on = [
    aws_s3_bucket.default
  ]
}

resource "aws_s3_bucket_versioning" "default_versioning" {
  bucket = aws_s3_bucket.default.id

  versioning_configuration {
    status = var.versioning_enabled
  }

  depends_on = [
    aws_s3_bucket.default
  ]
}

resource "aws_s3_bucket_acl" "default_acl" {
  bucket = aws_s3_bucket.default.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket.default
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default_encryption" {
  count = var.s3_bucket_encryption_enabled ? 1 : 0

  bucket = aws_s3_bucket.default.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

  depends_on = [
    aws_s3_bucket.default
  ]
}

resource "aws_iam_role" "default" {
  count              = local.enabled ? 1 : 0
  name               = module.this.id
  assume_role_policy = join("", data.aws_iam_policy_document.assume.*.json)
  tags               = module.this.tags
}

data "aws_iam_policy_document" "assume" {
  count = local.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.default.*.arn)
}

resource "aws_iam_policy" "default" {
  count  = local.enabled ? 1 : 0
  name   = module.this.id
  policy = join("", data.aws_iam_policy_document.default.*.json)
}

data "aws_iam_policy_document" "default" {
  count = local.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*",
      "iam:PassRole",
      "logs:PutRetentionPolicy",
    ]

    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "s3" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.s3.*.arn)
}

resource "aws_iam_policy" "s3" {
  count  = local.enabled ? 1 : 0
  name   = "${module.this.id}-s3"
  policy = join("", data.aws_iam_policy_document.s3.*.json)
}

data "aws_s3_bucket" "website" {
  count  = local.enabled && var.website_bucket_name != "" ? 1 : 0
  bucket = var.website_bucket_name
}

# CARPETAS DE ENVCONFIG
data "aws_s3_bucket" "envconfig" {
  bucket = "envconfig"
}

# CARPETA DE $BRANCH-envfiles
data "aws_s3_bucket" "envfiles" {
  bucket = "clave-envfiles-${module.this.stage}"
}

resource "aws_s3_bucket_object" "envfile" {
  bucket = data.aws_s3_bucket.envfiles.id
  acl    = "private"
  key    = "${module.this.name}/${module.this.name}"
  source = "/dev/null"
}

data "aws_iam_policy_document" "s3" {
  count = local.enabled ? 1 : 0

  statement {
    sid = ""

    actions   = ["s3:*"]
    resources = ["*"]

    effect = "Allow"
  }

  dynamic "statement" {
    for_each = var.website_bucket_name != "" ? ["true"] : []
    content {
      sid = ""

      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject",
        "s3:PutObjectAcl",
      ]

      resources = [
        join("", data.aws_s3_bucket.website.*.arn),
        "${join("", data.aws_s3_bucket.website.*.arn)}/*"
      ]

      effect = "Allow"
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = local.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
}

resource "aws_iam_policy" "codebuild" {
  count  = local.enabled ? 1 : 0
  name   = "${module.this.id}-codebuild"
  policy = join("", data.aws_iam_policy_document.codebuild.*.json)
}

data "aws_iam_policy_document" "codebuild" {
  count = local.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "codebuild:*"
    ]

    resources = [module.codebuild.project_id]
    effect    = "Allow"
  }
}

module "sa_role" {
  count = var.buckets_names != null || var.has_ses || var.lambda_function != null ? 1 : 0

  source  = "./aws-sa-role"

  role_name       = "${module.this.name}-${module.this.stage}"
  environment     = module.this.stage
  buckets_names   = var.buckets_names
  readonly        = var.readonly
  has_ses         = var.has_ses
  lambda_function = var.lambda_function
  asg             = var.asg

  cluster_oidc_issuer_urls = var.cluster_oidc

  tags = {
    Terraform   = true
    Environment = "${module.this.stage}"
  }
}

module "codebuild" {
  source = "./aws-codebuild"

  build_image           = var.build_image
  build_compute_type    = var.build_compute_type
  buildspec             = "buildspec_helm.yml"
  attributes            = ["build"]
  privileged_mode       = var.privileged_mode
  aws_region            = var.region != "" ? var.region : data.aws_region.default.name
  aws_account_id        = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.default.account_id
  image_repo_name       = var.image_repo_name
  image_tag             = var.image_tag
  github_token          = var.github_oauth_token
  environment_variables = var.env_vars
  cache_bucket_name     = aws_s3_bucket.default.bucket
  vpc_config            = var.vpc_config
  context               = module.this.context

  depends_on = [
    aws_ecr_repository.default,
    aws_s3_bucket.default
  ]
}

resource "aws_codepipeline" "default" {
  count = local.enabled ? 1 : 0

  name     = module.this.id
  role_arn = join("", aws_iam_role.default.*.arn)
  tags     = module.this.tags

  artifact_store {
    location = join("", aws_s3_bucket.default.*.bucket)
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration = {
        OAuthToken           = var.github_oauth_token
        Owner                = var.repo_owner
        Repo                 = var.repo_name
        Branch               = var.branch
        PollForSourceChanges = var.poll_source_changes
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["code"]
      output_artifacts = ["package"]

      configuration = {
        ProjectName = module.codebuild.project_name
      }
    }
  }

  dynamic "stage" {
    for_each = var.elastic_beanstalk_application_name != "" && var.elastic_beanstalk_environment_name != "" ? ["true"] : []
    content {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ElasticBeanstalk"
        input_artifacts = ["package"]
        version         = "1"

        configuration = {
          ApplicationName = var.elastic_beanstalk_application_name
          EnvironmentName = var.elastic_beanstalk_environment_name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.website_bucket_name != "" ? ["true"] : []
    content {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "S3"
        input_artifacts = ["package"]
        version         = "1"

        configuration = {
          BucketName = var.website_bucket_name
          Extract    = "true"
          CannedACL  = var.website_bucket_acl
        }
      }
    }
  }
}

resource "random_password" "webhook_secret" {
  count  = local.webhook_enabled ? 1 : 0
  length = 32
  special = false
}

resource "aws_codepipeline_webhook" "default" {
  count = local.webhook_count

  name            = module.this.id
  authentication  = var.webhook_authentication
  target_action   = var.webhook_target_action
  target_pipeline = join("", aws_codepipeline.default.*.name)

  authentication_configuration {
    secret_token = local.webhook_secret
  }

  filter {
    json_path    = var.webhook_filter_json_path
    match_equals = var.webhook_filter_match_equals
  }

  depends_on = [
    aws_codepipeline.default[0]
  ]
}

module "github_webhook" {
  source  = "cloudposse/repository-webhooks/github"
  version = "0.12.0"

  enabled              = local.webhook_enabled
  github_organization  = var.repo_owner
  github_repositories  = [var.repo_name]
  github_token         = var.github_oauth_token
  webhook_url          = local.webhook_url
  webhook_secret       = local.webhook_secret
  webhook_content_type = "json"
  events               = var.github_webhook_events

  context = module.this.context
}