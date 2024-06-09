provider "aws" {
  region = "us-east-1"
}


data "aws_vpc" "main" {
  id = "vpc-01d51a031e1582ddb" 
}


data "aws_subnet" "main" {
  id = "subnet-0512de6eda1d6c2db"  
}

resource "aws_security_group" "main" {
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "hello-world-cluster"
}

resource "aws_ecs_task_definition" "hello_world" {
  family                   = "hello-world-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "hello-world-app"
      image     = "YOUR_DOCKERHUB_USERNAME/hello-world-app:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = "hello-world-service-${timestamp()}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.hello_world.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.main.id]
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = true
  }
}
