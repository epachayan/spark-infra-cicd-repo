variable "name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "staging_tg_name" { type = string }
variable "prod_tg_name" { type = string }
variable "health_check_path" { type = string }
variable "tags" { type = map(string) }
