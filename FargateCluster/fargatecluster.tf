terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}
provider "aws" {
  region = var.region
}

# Creating a service in cloudmap
resource "aws_service_discovery_service" "main" {
  name = "${var.app_name}-${var.environment}"

  dns_config {
    namespace_id = var.FargateNameSpaceID

    dns_records {
      ttl  = 60
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }
}

# Creating an API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.app_name}-${var.environment}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "main" {
  api_id = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"
  connection_id = var.NetworkStackVpcLinkId
  connection_type = "VPC_LINK"
  integration_method = "ANY"
  integration_uri = aws_service_discovery_service.main.arn
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target = "integrations/${aws_apigatewayv2_integration.main.id}"
}

# API Gateway Default Stage
resource "aws_apigatewayv2_stage" "Default" {
  api_id = aws_apigatewayv2_api.main.id
  name   = "$default"
  auto_deploy = true
}

# ECS CLuster for fargate
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-${var.environment}-Cluster"
  tags = var.tags
}

# Fargate Service Security Group- Allowing inbound from VPC Link security group
resource "aws_security_group" "ecs_service" {
  name        = "fargate-task-security-group-${var.environment}"
  description = "security group for fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "tcp"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [var.VPCLinkSG]
   
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    description = "Allow all outbound traffic by default"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Fargate Service
resource "aws_ecs_service" "main" {

  name            = "${var.app_name}-${var.environment}"
  cluster         = aws_ecs_cluster.main.name
  task_definition = "${aws_ecs_task_definition.app.family}:${max(aws_ecs_task_definition.app.revision, data.aws_ecs_task_definition.app.revision)}"
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_service.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
    port = "8080"
  }
}

# Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/fargate/${var.app_name}-${var.environment}"
  retention_in_days = 30
  tags = var.tags
}

# Cloudwatch Log Stream
resource "aws_cloudwatch_log_stream" "main" {
  name           = "${var.app_name}-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.main.name
}

data "aws_ecs_task_definition" "app" {
  task_definition = aws_ecs_task_definition.app.family
  depends_on      = [aws_ecs_task_definition.app]
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family             = "${var.app_name}-${var.environment}"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.task_definition_task_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"]
  cpu    = "512"
  memory = "1024"
  container_definitions = jsonencode([
    {
      name : var.containter_name,
      image : var.image_URI,
      networkMode : "awsvpc",
      logConfiguration : {
        logDriver : "awslogs",
        "options" : {
          "awslogs-group" : aws_cloudwatch_log_group.main.name,
          "awslogs-region" : "ap-southeast-2",
          "awslogs-stream-prefix" : "ecs"
        }
      },
      portMappings : [
        {
          containerPort : var.app_port
          protocol : "tcp",
          hostPort : var.app_port
        }
      ],
      environment : [
        {
          name : "ENV",
          value : var.environment
        }
      ]
    }
  ])
  tags = var.tags
}

# Role for task Definition
resource "aws_iam_role" "task_definition_task_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


# Custom Policy
data "aws_iam_policy_document" "app_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

# Assign the custome policy to task execution role
resource "aws_iam_role_policy" "app_policy" {
  name   = "${var.app_name}-${var.environment}-ecs-policy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = data.aws_iam_policy_document.app_policy.json
}