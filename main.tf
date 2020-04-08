module "default_label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.16.0"
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
  attributes = var.attributes
  delimiter  = var.delimiter
}

module "alb" {
  source             = "git::https://github.com/cloudposse/terraform-aws-alb.git?ref=tags/0.8.0"
  name               = var.name
  namespace          = var.namespace
  stage              = var.stage
  attributes         = compact(concat(var.attributes, ["alb"]))
  vpc_id             = var.vpc_id
  ip_address_type    = "ipv4"
  subnet_ids         = var.public_subnet_ids
  access_logs_region = var.region

  http_enabled              = false
  https_enabled             = true
  https_port                = 443
  target_group_port         = 80
  https_ingress_cidr_blocks = var.ingress_cidr_blocks_https
  certificate_arn           = var.certificate_arn
  health_check_interval     = 60
  health_check_path         = "/api/v1/info"
  health_check_matcher      = "200"

  alb_access_logs_s3_bucket_force_destroy = true

  # Shorten name to meet 32 char restriction
  target_group_name = join(var.delimiter, [module.default_label.id, "alb", "dflt"])
}

module "nlb" {
  source             = "git::https://github.com/cloudposse/terraform-aws-nlb.git?ref=tags/0.2.0"
  name               = var.name
  namespace          = var.namespace
  stage              = var.stage
  attributes         = compact(concat(var.attributes, ["nlb"]))
  vpc_id             = var.vpc_id
  ip_address_type    = "ipv4"
  subnet_ids         = var.public_subnet_ids
  access_logs_region = var.region

  tcp_enabled           = true
  tcp_port              = 2222
  target_group_port     = 2222
  certificate_arn       = var.tsa_certificate_arn
  health_check_protocol = "HTTP"
  health_check_port     = 80
  health_check_interval = 30
  health_check_path     = "/api/v1/info"

  nlb_access_logs_s3_bucket_force_destroy = true

  # Shorten name to meet 32 char restriction
  target_group_name = join(var.delimiter, [module.default_label.id, "nlb", "dflt"])
}

data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"
    resources = [
      "${var.keys_bucket_arn}",
      "${var.keys_bucket_arn}/*"
    ]
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
  }
}

resource "aws_iam_policy" "default" {
  name   = module.default_label.id
  policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = module.web.ecs_task_role_name
  policy_arn = aws_iam_policy.default.arn
}

module "download_keys_container_definition" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.22.0"
  container_name  = "download_keys"
  container_image = "mesosphere/aws-cli:latest"
  essential       = false
  command = [
    "s3",
    "cp",
    "s3://${var.keys_bucket_id}",
    "/concourse-keys",
    "--recursive"
  ]

  port_mappings = []
  mount_points = [
    {
      containerPath = "/concourse-keys",
      sourceVolume  = "concourse_keys"
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-region"        = var.region
      "awslogs-group"         = module.web.cloudwatch_log_group_name
      "awslogs-stream-prefix" = "keys"
    }
    secretOptions = null
  }
}

resource "random_password" "default" {
  length      = 24
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  number      = true
  special     = false
}

locals {
  concourse_db_password = coalesce(var.concourse_db_password, random_password.default.result)
}

module "create_db_container_definition" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition.git?ref=tags/0.22.0"
  container_name  = "create_db"
  container_image = "postgres:${var.db_version}"
  essential       = false
  port_mappings   = []
  command = [
    "/bin/sh",
    "-exc",
    # This command creates the database and adds a role for ATC with privileges.
    #
    # It is complicated by the fact that it is designed to fail on genuine problems,
    # yet run to completion without error if the aforementioned steps are in any
    # state of application (e.g., unapplied, database created but role not created,
    # fully applied, etc.).
    #
    # The end effect is that the init containers are idempotent, and we can thus
    # update the task definition at will.
    <<-EOT
      psql <<-EOC
        \set ON_ERROR_STOP on
        SELECT 'CREATE DATABASE $CONCOURSE_POSTGRES_DATABASE' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$CONCOURSE_POSTGRES_DATABASE')\gexec
        DO
        \$\$
        BEGIN
          IF NOT EXISTS (
            SELECT
              FROM  pg_catalog.pg_roles
              WHERE rolname = '$CONCOURSE_POSTGRES_USER') THEN
            CREATE ROLE $CONCOURSE_POSTGRES_USER LOGIN PASSWORD '$CONCOURSE_POSTGRES_PASSWORD';
            GRANT ALL PRIVILEGES ON DATABASE $CONCOURSE_POSTGRES_DATABASE TO $CONCOURSE_POSTGRES_USER;
          ELSE
            ALTER ROLE $CONCOURSE_POSTGRES_USER WITH PASSWORD '$CONCOURSE_POSTGRES_PASSWORD';
          END IF;
        END
        \$\$;
      EOC
    EOT
  ]

  environment = [
    { name = "PGUSER", value = var.db_admin_username },
    { name = "PGHOST", value = var.db_hostname },
    { name = "PGPORT", value = var.db_port },
    { name = "PGDATABASE", value = var.db_name },
    { name = "PGPASSWORD", value = var.db_admin_password },
    { name = "CONCOURSE_POSTGRES_USER", value = var.concourse_db_username },
    { name = "CONCOURSE_POSTGRES_PASSWORD", value = local.concourse_db_password },
    { name = "CONCOURSE_POSTGRES_DATABASE", value = var.concourse_db_name },
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-region"        = var.region
      "awslogs-group"         = module.web.cloudwatch_log_group_name
      "awslogs-stream-prefix" = "create_db"
    }
    secretOptions = null
  }
}

# ECS Cluster (needed even if using FARGATE launch type)
resource "aws_ecs_cluster" "default" {
  name = module.default_label.id
}

resource "aws_sns_topic" "sns_topic" {
  name = module.default_label.id
  tags = module.default_label.tags
}

module "web" {
  source     = "git::https://github.com/cloudposse/terraform-aws-ecs-web-app.git?ref=tags/0.31.0"
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
  attributes = compact(concat(var.attributes, ["web"]))
  delimiter  = var.delimiter
  region     = var.region
  vpc_id     = var.vpc_id

  container_image = "${var.concourse_docker_image}:${var.concourse_version}"
  command         = ["web"]
  task_cpu        = 1024
  task_memory     = 2048

  init_containers = [
    {
      container_definition = module.download_keys_container_definition.json_map,
      condition            = "SUCCESS"
    },
    {
      container_definition = module.create_db_container_definition.json_map,
      condition            = "SUCCESS"
    }
  ]

  container_port     = 80
  nlb_container_port = 2222

  port_mappings = [
    {
      hostPort      = 80,
      containerPort = 80,
      protocol      = "tcp"
    },
    {
      hostPort      = 2222,
      containerPort = 2222,
      protocol      = "tcp"
    },
  ]

  ulimits = [
    {
      name      = "nofile",
      softLimit = 20000,
      hardLimit = 20000
    }
  ]

  volumes = [
    {
      name                        = "concourse_keys",
      host_path                   = null,
      docker_volume_configuration = []
    }
  ]

  mount_points = [
    {
      containerPath = "/concourse-keys",
      sourceVolume  = "concourse_keys"
    }
  ]

  environment = [
    { name = "CONCOURSE_POSTGRES_HOST", value = var.db_hostname },
    { name = "CONCOURSE_POSTGRES_PORT", value = var.db_port },
    { name = "CONCOURSE_POSTGRES_USER", value = var.concourse_db_username },
    { name = "CONCOURSE_POSTGRES_PASSWORD", value = local.concourse_db_password },
    { name = "CONCOURSE_POSTGRES_DATABASE", value = var.concourse_db_name },
    { name = "CONCOURSE_EXTERNAL_URL", value = var.external_url_https },
    { name = "CONCOURSE_BIND_PORT", value = 80 },
    { name = "CONCOURSE_GITHUB_CLIENT_ID", value = var.concourse_github_auth_client_id },
    { name = "CONCOURSE_GITHUB_CLIENT_SECRET", value = var.concourse_github_auth_client_secret },
    { name = "CONCOURSE_MAIN_TEAM_GITHUB_ORG", value = var.concourse_main_team_github_org },
    { name = "CONCOURSE_MAIN_TEAM_GITHUB_TEAM", value = var.concourse_main_team_github_team },
    { name = "CONCOURSE_AWS_SSM_REGION", value = var.region },
    { name = "LAUNCH_TYPE", value = "FARGATE" },
    { name = "VPC_ID", value = var.vpc_id }
  ]

  codepipeline_enabled      = false
  repo_owner                = var.concourse_main_team_github_org
  github_webhooks_token     = ""
  github_webhooks_anonymous = true
  github_oauth_token        = "dummy"
  webhook_enabled           = false
  autoscaling_enabled       = var.autoscaling_enabled
  autoscaling_dimension     = var.autoscaling_dimension

  aws_logs_region        = var.region
  log_retention_in_days  = 7
  ecs_cluster_arn        = aws_ecs_cluster.default.arn
  ecs_cluster_name       = aws_ecs_cluster.default.name
  ecs_private_subnet_ids = var.private_subnet_ids

  use_alb_security_group                            = true
  alb_security_group                                = module.alb.security_group_id
  alb_target_group_alarms_insufficient_data_actions = [aws_sns_topic.sns_topic.arn]
  alb_target_group_alarms_ok_actions                = [aws_sns_topic.sns_topic.arn]
  alb_target_group_alarms_alarm_actions             = [aws_sns_topic.sns_topic.arn]

  use_nlb_cidr_blocks           = true
  nlb_cidr_blocks               = ["0.0.0.0/0"]
  nlb_ingress_target_group_arn  = module.nlb.default_target_group_arn
  alb_arn_suffix                = module.alb.alb_arn_suffix

  alb_ingress_healthcheck_path = "/api/v1/info"

  # Without authentication, both HTTP and HTTPS endpoints are supported
  alb_ingress_unauthenticated_listener_arns       = [module.alb.https_listener_arn]
  alb_ingress_unauthenticated_listener_arns_count = 1

  # All paths are unauthenticated
  alb_ingress_unauthenticated_paths             = ["/*"]
  alb_ingress_listener_unauthenticated_priority = 100
}

data "aws_vpc" "default" {
  id = var.vpc_id
}

// TODO: Determine if there is a way to restrict this to traffic from
// the full set of ALB IPs rather than the VPC block. Also, determine
// if this can be moved to the terraform-aws-ecs-alb-service-task
// module
resource "aws_security_group_rule" "tsa_http_health_check_in" {
  type              = "ingress"
  security_group_id = module.web.ecs_service_security_group_id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.default.cidr_block]
  description       = "NLB health check ingress rule"
}
