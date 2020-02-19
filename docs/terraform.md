## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| attributes | Additional attributes (e.g. `1`) | list(string) | `<list>` | no |
| autoscaling_dimension | Dimension to autoscale on (valid options: cpu, memory) | string | `cpu` | no |
| autoscaling_enabled | A boolean to enable/disable Autoscaling policy for ECS Service | bool | `false` | no |
| certificate_arn | ARN of the ALB (HTTPS) certificate | string | - | yes |
| chamber_kms_key_arn | ARN of the chamber KMS key | string | `` | no |
| concourse_db_name | Concourse PostgreSQL database name | string | `concourse` | no |
| concourse_db_password | Password for the Concourse database user | string | `` | no |
| concourse_db_username | Username for the Concourse database | string | `concourse` | no |
| concourse_docker_image | Concourse docker image | string | `concourse/concourse` | no |
| concourse_github_auth_client_id | Github client id | string | `null` | no |
| concourse_github_auth_client_secret | Github client secret | string | `null` | no |
| concourse_main_team_github_org | Github team that can login | string | `null` | no |
| concourse_main_team_github_team | Github team that can login | string | `null` | no |
| concourse_version | Concourse version to use | string | `5.8.0` | no |
| db_admin_password | Admin password of the PostgreSQL database server | string | - | yes |
| db_admin_username | Admin user of the PostgreSQL database server | string | - | yes |
| db_hostname | PostgreSQL server hostname or IP | string | - | yes |
| db_name | Default PostgreSQL database | string | `postgres` | no |
| db_port | Port of the PostgreSQL server | string | `5432` | no |
| db_security_group_id | Database security group ID | string | - | yes |
| db_version | PostgreSQL engine version used in the Concourse database server | string | - | yes |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name` and `attributes` | string | `-` | no |
| external_url_https | Concourse external URL (fully qualified, e.g. `https://concourse.prod.acme.co`) | string | - | yes |
| ingress_cidr_blocks_https | List of CIDR blocks allowed to access Concourse over HTTPS | list(string) | `<list>` | no |
| keys_bucket_arn | ARN of the bucket holding the keys | string | - | yes |
| keys_bucket_id | ID of the bucket holding the keys | string | - | yes |
| name | Application or solution name (e.g. `app`) | string | `concourse` | no |
| namespace | Namespace (e.g. `cp` or `cloudposse`) | string | - | yes |
| private_subnet_ids | List of private VPC subnet IDs | list(string) | - | yes |
| public_subnet_ids | List of public VPC subnet IDs | list(string) | - | yes |
| region | AWS Region for deployment | string | - | yes |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | string | - | yes |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | map(string) | `<map>` | no |
| tsa_certificate_arn | ARN of the NLB certificate | string | - | yes |
| vpc_id | VPC ID for deployment | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | ALB DNS name |
| ecs_service_security_group_id | Security Group ID of the ECS task |
| ecs_task_role_name | Name of the ECS task role |
| nlb_dns_name | NLB DNS name |

