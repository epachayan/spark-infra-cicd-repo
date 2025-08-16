resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  tags               = var.tags
}

resource "aws_lb_target_group" "staging" {
  name     = substr(var.staging_tg_name, 0, 32)
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    matcher             = "200"
  }
  tags = merge(var.tags, { Environment = "staging" })
}

resource "aws_lb_target_group" "prod" {
  name     = substr(var.prod_tg_name, 0, 32)
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    matcher             = "200"
  }
  tags = merge(var.tags, { Environment = "production" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching rule. Try /staging or /prod"
      status_code  = "200"
    }
  }
}

# Path-based routing to target groups
resource "aws_lb_listener_rule" "staging_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.staging.arn
  }
  condition {
    path_pattern { values = ["/staging*", "/develop*"] }
  }
}

resource "aws_lb_listener_rule" "prod_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod.arn
  }
  condition {
    path_pattern { values = ["/prod*", "/"] }
  }
}
