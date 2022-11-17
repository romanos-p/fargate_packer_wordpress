# A random string to prefix the secrets name because it must be
# unique and secrets have to wait 7 days before getting deleted
resource "random_string" "random_suffix" {
  length  = 3
  special = false
  upper   = false
}

# The secret with login information to the docker registry
resource "aws_secretsmanager_secret" "secrets" {
  name = "registrysecrets-${random_string.random_suffix.result}"
}
resource "aws_secretsmanager_secret_version" "secretversion" {
  secret_id = aws_secretsmanager_secret.secrets.id
  secret_string = jsonencode({
    "username" : "${var.DOCKER_REGISTRY_USER}",
    "password" : "${var.DOCKER_REGISTRY_PASS}"
  })

}

# The ECS cluster
resource "aws_ecs_cluster" "cluster" {
  name = "cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# The IAM role with Assume Role permissions for the ECS Task
resource "aws_iam_role" "task_execution" {
  name = "task-execution-ecs"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Sid" : "",
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "ecs-tasks.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}
# An inline policy with permissions to read the secrets created above
resource "aws_iam_role_policy" "secrets_policy" {
  name = "access-to-repository-secrets"
  role = aws_iam_role.task_execution.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource" : ["${aws_secretsmanager_secret.secrets.arn}"]
    }]
  })
}

# The Task that runs in the ECS cluster
resource "aws_ecs_task_definition" "task" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.task_execution.arn
  container_definitions = jsonencode([
    {
      "name" : "wp",
      "image" : "${var.DOCKER_REGISTRY_IMG}",
      "repositoryCredentials" : {
        "credentialsParameter" : "${aws_secretsmanager_secret.secrets.arn}"
      },
      "executionRoleArn" : "${aws_iam_role.task_execution.arn}",
      "cpu" : 512,
      "memory" : 2048,
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ],
      "environment" : [
        {"name": "DB_NAME", "value": "${data.aws_db_instance.rds.db_name}"},
        {"name": "DB_USER", "value": "${random_string.rds_user.result}"},
        {"name": "DB_PASSWORD", "value": "${random_string.rds_pass.result}"},
        {"name": "DB_HOST", "value": "${data.aws_db_instance.rds.endpoint}"}
      ]
    }
  ])
}

# The service that contains the Task above
resource "aws_ecs_service" "service" {
  name             = "service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.sg.id]
    subnets          = [aws_subnet.subnet.id]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}