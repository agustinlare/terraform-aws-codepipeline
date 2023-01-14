locals {
  env       = "dev"
  role_name = "test_role_name"
  oidc      = ["some.oidc.value.ok"]
  # buckets_names = ["clave-documents-prod"]
  # readonly      = false
  #has_ses       = true
}

# module "ses" {
#   source = "../"

#   environment              = local.env
#   role_name                = local.role_name
#   cluster_oidc_issuer_urls = local.oidc

#   has_ses = local.has_ses

#   tags = {}
# }

# module "buckets" {
#   source = "../"

#   environment              = local.env
#   role_name                = local.role_name
#   cluster_oidc_issuer_urls = local.oidc

#   buckets_names = local.buckets_names
#   readonly      = local.readonly


#   tags = {}
# }

module "lambda" {
  source = "../"

  environment              = local.env
  role_name                = local.role_name
  cluster_oidc_issuer_urls = local.oidc

  lambda_function = ["este_es_el_nombre", "esta_esta_es_tra"]
  asg = ["clave-recontraretruchooooo"]

  tags = {}
}