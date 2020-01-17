variable "region" {
  type        = string
  description = "AWS Region for deployment"
}

variable "namespace" {
  type        = string
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "stage" {
  type        = string
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}

variable "name" {
  type        = string
  description = "Application or solution name (e.g. `app`)"
  default     = "concourse"
}

variable "delimiter" {
  type        = string
  description = "Delimiter to be used between `namespace`, `stage`, `name` and `attributes`"
  default     = "-"
}

variable "attributes" {
  type        = list(string)
  description = "Additional attributes (e.g. `1`)"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)"
  default     = {}
}

variable "ingress_cidr_blocks_https" {
  type        = list(string)
  description = "List of CIDR blocks allowed to access Concourse over HTTPS"
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the ALB (HTTPS) certificate"
}

variable "tsa_certificate_arn" {
  type        = string
  description = "ARN of the NLB certificate"
}

variable "external_url_https" {
  type        = string
  description = "Concourse external URL (fully qualified, e.g. `https://concourse.prod.acme.co`)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for deployment"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public VPC subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private VPC subnet IDs"
}

variable "db_security_group_id" {
  type        = string
  description = "Database security group ID"
}

variable "db_hostname" {
  description = "PostgreSQL server hostname or IP"
  type        = string
}

variable "db_port" {
  type        = string
  description = "Port of the PostgreSQL server"
  default     = "5432"
}

variable "db_name" {
  type        = string
  description = "Default PostgreSQL database"
  default     = "postgres"
}

variable "db_version" {
  type        = string
  description = "PostgreSQL engine version used in the Concourse database server"
}

variable "db_admin_username" {
  type        = string
  description = "Admin user of the PostgreSQL database server"
}

variable "db_admin_password" {
  type        = string
  description = "Admin password of the PostgreSQL database server"
}

variable "concourse_db_name" {
  type        = string
  description = "Concourse PostgreSQL database name"
  default     = "concourse"
}

variable "concourse_db_username" {
  type        = string
  description = "Username for the Concourse database"
  default     = "concourse"
}

variable "concourse_db_password" {
  type        = string
  description = "Password for the Concourse database user"
  default     = ""
}

variable "concourse_github_auth_client_id" {
  type        = string
  description = "Github client id"
  default     = null
}

variable "concourse_github_auth_client_secret" {
  type        = string
  description = "Github client secret"
  default     = null
}

variable "concourse_main_team_github_org" {
  type        = string
  description = "Github team that can login"
  default     = null
}

variable "concourse_main_team_github_team" {
  type        = string
  description = "Github team that can login"
  default     = null
}

variable "concourse_docker_image" {
  type        = string
  description = "Concourse docker image"
  default     = "concourse/concourse"
}

variable "concourse_version" {
  type        = string
  description = "Concourse version to use"
  default     = "5.8.0"
}

variable "keys_bucket_id" {
  type        = string
  description = "ID of the bucket holding the keys"
}

variable "keys_bucket_arn" {
  type        = string
  description = "ARN of the bucket holding the keys"
}

variable "chamber_kms_key_arn" {
  type        = string
  description = "ARN of the chamber KMS key"
  default     = ""
}

variable "autoscaling_enabled" {
  type        = bool
  description = "A boolean to enable/disable Autoscaling policy for ECS Service"
  default     = false
}

variable "autoscaling_dimension" {
  type        = string
  description = "Dimension to autoscale on (valid options: cpu, memory)"
  default     = "cpu"
}
