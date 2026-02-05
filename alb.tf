resource "aws_security_group" "alb_sg" {
  name        = "tracknow-alb-sg"
  description = "ALB SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from anywhere"
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

  tags = {
    Name = "tracknow-alb-sg"
  }
}

resource "aws_lb" "this" {
  name               = "tracknow-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = module.vpc.public_subnets

  tags = {
    Name = "tracknow-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "tracknow-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "tracknow-app-tg"
  }
}

resource "aws_lb_target_group_attachment" "app_ec2" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = module.ec2_moodle.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
