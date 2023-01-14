# tf-module-sa-roles

<!--- BEGIN_TF_DOCS --->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.4 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_id | AWS Account ID where the resources will be generated | `string` | `null` | no |
| aws\_region | AWS Region to create al resources | `string` | `null` | no |
| buckets\_names | List of S3 to assign permissions on IAM statements for S3 | `list(string)` | `null` | no |
| cluster\_oidc\_issuer\_urls | EKS Cluster OIDC URLs | `list(string)` | `null` | no |
| custom\_policy\_for\_dynamo | List containing a set of custom Actions and Resources to set on IAM statements for DynamoDB | `list(any)` | `null` | no |
| custom\_policy\_for\_ses | List containing a set of custom Actions and Resources to set on IAM statements for SES | `list(any)` | `null` | no |
| custom\_policy\_for\_sns | List containing a set of custom Actions and Resources to set on IAM statements for SNS | `list(any)` | `null` | no |
| environment | Environment Name (usually used as a suffix) | `string` | `null` | no |
| event\_bus\_names | List of names of event-bus to assign permissions on IAM statements for EB | `list(string)` | `null` | no |
| has\_dynamo | To indicate this role will have access to DynamoDB | `bool` | `false` | no |
| has\_ses | To indicate this role will have access to SES | `bool` | `false` | no |
| has\_sns | To indicate this role will have access to SNS | `bool` | `false` | no |
| role\_basename | Role Basename (usually used as a prefix) | `string` | `"pod-role"` | no |
| role\_name | Name of the IAM Role | `string` | `null` | no |
| sqs\_names | List of names of SQS to assign permissions on IAM statements for SQS | `list(string)` | `null` | no |
| ssm\_names | List of names of Parameters names to assign permissions on IAM statements for SSM | `list(string)` | `null` | no |
| tags | Tags to apply in every resource that supports it | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| dynamodb\_access\_arn | n/a |
| dynamodb\_access\_id | n/a |
| event\_bridge\_write\_access\_arn | n/a |
| event\_bridge\_write\_access\_id | n/a |
| s3\_buckets\_readwrite\_access\_arn | n/a |
| s3\_buckets\_readwrite\_access\_id | n/a |
| service\_account\_role\_arn | n/a |
| service\_account\_role\_name | n/a |
| ses\_access\_arn | n/a |
| ses\_access\_id | n/a |
| sns\_access\_arn | n/a |
| sns\_access\_id | n/a |
| sqs\_write\_access\_arn | n/a |
| sqs\_write\_access\_id | n/a |
| ssm\_readonly\_permission\_arn | n/a |
| ssm\_readonly\_permission\_id | n/a |

<!--- END_TF_DOCS --->
