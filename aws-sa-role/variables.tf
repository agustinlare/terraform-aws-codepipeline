variable "aws_region" {
  description = "AWS Region to create al resources"
  type        = string
  default     = null
}

variable "account_id" {
  description = "AWS Account ID where the resources will be generated"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment Name (usually used as a suffix)"
  type        = string
  default     = null
}

variable "role_basename" {
  description = "Role Basename (usually used as a prefix)"
  type        = string
  default     = "pod-role"
}

variable "role_name" {
  description = "Name of the IAM Role"
  type        = string
  default     = null
}

variable "cluster_oidc_issuer_urls" {
  description = "EKS Cluster OIDC URLs"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply in every resource that supports it"
  type        = map(string)
}

variable "buckets_names" {
  description = "List of S3 to assign permissions on IAM statements for S3"
  type        = list(string)
  default     = null
}

variable "readonly" {
  description = "Type of permissions to be granted at bucket label"
  type        = bool
  default     = false
}

variable "has_ses" {
 description = "To indicate this role will have access to SES"
 type        = bool
 default     = false
}

variable "custom_policy_for_ses" {
 description = "List containing a set of custom Actions and Resources to set on IAM statements for SES"
 type        = list(any)
 default     = null
}

variable "lambda_function" {
  type = list(any)
  default = null
  description = "Allows to invoke specific lambda function"
}

variable "asg" {
  type = list(any)
  default = null
  description = "Allows the modification of the listed autoscaling groups"
}

#variable "event_bus_names" {
#  description = "List of names of event-bus to assign permissions on IAM statements for EB"
#  type        = list(string)
#  default     = null
#}

#variable "has_dynamo" {
#  description = "To indicate this role will have access to DynamoDB"
#  type        = bool
#  default     = false
#}
#
#variable "custom_policy_for_dynamo" {
#  description = "List containing a set of custom Actions and Resources to set on IAM statements for DynamoDB"
#  type        = list(any)
#  default     = null
#}
#
#variable "has_sns" {
#  description = "To indicate this role will have access to SNS"
#  type        = bool
#  default     = false
#}
#
#variable "custom_policy_for_sns" {
#  description = "List containing a set of custom Actions and Resources to set on IAM statements for SNS"
#  type        = list(any)
#  default     = null
#}
#
#
#variable "ssm_names" {
#  description = "List of names of Parameters names to assign permissions on IAM statements for SSM"
#  type        = list(string)
#  default     = null
#}
#
#variable "sqs_names" {
#  description = "List of names of SQS to assign permissions on IAM statements for SQS"
#  type        = list(string)
#  default     = null
#}
