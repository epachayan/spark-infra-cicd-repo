output "alb_arn" { value = aws_lb.this.arn }
output "alb_dns_name" { value = aws_lb.this.dns_name }
output "staging_tg_arn" { value = aws_lb_target_group.staging.arn }
output "prod_tg_arn" { value = aws_lb_target_group.prod.arn }
