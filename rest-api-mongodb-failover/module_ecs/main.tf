# ECS application running on Fargate inside 2 private subnets
provider "aws" {
  region = var.region
}
data "aws_ecr_image" "service_image" {
  repository_name = var.ecr_repository_ecommerce_rest_api
  image_tag       = var.ecr_tag_ecommerce_rest_api
}
data "aws_iam_role" "rest_api_task_role" {
  name = var.task_IAM_role_name
}
data "aws_iam_role" "ecs_task_role_execution_standard" {
  name = "ecsTaskExecutionRole"
}
data "aws_subnet" "ecs_service_subnet_first_option" {
  id = var.ecs_service_subnet_first_option
}
data "aws_subnet" "ecs_service_subnet_second_option" {
  id = var.ecs_service_subnet_second_option
}
data "aws_security_group" "load_balancer_security_group" {
  id = var.load_balancer_security_group_id
}
data "aws_security_group" "mongo_db_security_group" {
  id = var.mongo_db_security_group_id
}
data "aws_vpc" "my_vpc" {
  id = var.vpc_id
}
data "aws_lb_target_group" "rest_api_fargate_target_group" {
  arn  = var.fargate_target_group_arn
  name = var.fargate_target_group_name
}

resource "aws_security_group" "ecommerce_rest_api_security_group" {
  name        = "ecommerce_rest_api_security_group"
  description = "allow http only from alb, allow all traffic outbound"
  vpc_id      = data.aws_vpc.my_vpc.id
}
resource "aws_vpc_security_group_ingress_rule" "inbound_allow_http_from_alb" {
  security_group_id            = aws_security_group.ecommerce_rest_api_security_group.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.load_balancer_security_group.id
}
resource "aws_vpc_security_group_egress_rule" "outbound_allow_all_alb" {
  security_group_id = aws_security_group.ecommerce_rest_api_security_group.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

# add security group to mongo_db to allow coming traffic form ecommerce rest api
resource "aws_vpc_security_group_ingress_rule" "inbound_allow_traffic_from_rest_api_to_mongodb" {
  security_group_id            = data.aws_security_group.mongo_db_security_group.id
  from_port                    = 27017
  to_port                      = 27017
  ip_protocol                  = "tcp"
  depends_on                   = [aws_security_group.ecommerce_rest_api_security_group]
  referenced_security_group_id = aws_security_group.ecommerce_rest_api_security_group.id
}

resource "aws_ecs_cluster" "rest_api_ecommerce_cluster" {
  name = "rest_api_ecommerce_cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
resource "aws_ecs_task_definition" "rest_api_task_definition" {
  family                   = "ecommerce_rest_api_service"
  task_role_arn            = data.aws_iam_role.rest_api_task_role.arn
  execution_role_arn       = data.aws_iam_role.ecs_task_role_execution_standard.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  container_definitions = jsonencode([
    {
      name      = "rest_api_container_ecommerce"
      image     = data.aws_ecr_image.service_image.image_uri
      cpu       = 1024
      memory    = 2048,
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          name          = "rest-api-80-tcp"
          appProtocol   = "http"
          protocol      = "tcp"
        },
        {
          name          = "mongo-port"
          containerPort = 27017
          hostPort      = 27017
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      environment = [
        {
          name  = "DATABASE_CREDENTIALS_SECRET_NAME"
          value = var.mongo_cluster_password_secret_name
        },
        {
          name  = "DATABASE_CREDENTIALS_SECRET_AWS_REGION"
          value = var.region
        },
        {
          name  = "DATABASE_HOST"
          value = var.db_host
        }
      ]
    },
  ])
}
# cluster is of type Fargate and is connected to Load balancer
resource "aws_ecs_service" "rest_api_ecommerce_service" {
  name            = "rest_api_ecommerce_service"
  cluster         = aws_ecs_cluster.rest_api_ecommerce_cluster.id
  task_definition = aws_ecs_task_definition.rest_api_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets = [data.aws_subnet.ecs_service_subnet_first_option.id,
    data.aws_subnet.ecs_service_subnet_second_option.id]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecommerce_rest_api_security_group.id]
  }
  load_balancer {
    container_name   = "rest_api_container_ecommerce"
    container_port   = 80
    target_group_arn = data.aws_lb_target_group.rest_api_fargate_target_group.arn
  }
  wait_for_steady_state = true
}

