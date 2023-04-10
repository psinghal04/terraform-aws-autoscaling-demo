terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# Security group for the Application Load Balancer. Ingress allowed only for Port 80, Egress allowed everywhere.
resource "aws_security_group" "alb_sg" {
  name        = "ALBSG"
  description = "ALBSG"
  vpc_id      = data.aws_vpc.default_vpc_data.id

  ingress {
    description = "TLS from VPC"
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

# Application Load Balancer. Able to send traffic to selected subnets in the VPC.
resource "aws_lb" "alb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [data.aws_subnet.us-east-1a.id, data.aws_subnet.us-east-1b.id]
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "ALBTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc_data.id
  health_check {
    healthy_threshold = 2
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_tg.arn
    type             = "forward"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "EC2WEBSG"
  description = "EC2WEBSG"
  vpc_id      = data.aws_vpc.default_vpc_data.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "HTTP from LB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "asg_lt" {
  name                   = "LT"
  description            = "LT"
  image_id               = data.aws_ami.amazon-2.id
  instance_type          = "t1.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = filebase64("${path.module}/setup.sh")
}

resource "aws_autoscaling_group" "aws_asg" {
  name = "HOLASG"
  launch_template {
    id = aws_launch_template.asg_lt.id
  }
  vpc_zone_identifier = [data.aws_subnet.us-east-1a.id, data.aws_subnet.us-east-1b.id]
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]
  max_size            = 6
  min_size            = 2
}

resource "aws_autoscaling_policy" "asg_pol" {
  name                      = "ASGPOL"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.aws_asg.name
  estimated_instance_warmup = 300
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = "30"
  }

}

data "aws_vpc" "default_vpc_data" {
  default = true
}

data "aws_subnet" "us-east-1a" {
  availability_zone = "us-east-1a"
}

data "aws_subnet" "us-east-1b" {
  availability_zone = "us-east-1b"
}

# Standard Amazon Linux 2 image for the US-EAST-1 region
data "aws_ami" "amazon-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  owners = ["amazon"]
}
