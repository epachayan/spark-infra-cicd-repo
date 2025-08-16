variable "name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_type" { type = string }
variable "key_name" { type = string }
variable "app_port" { type = number }
variable "staging_secret_arn" { type = string }
variable "prod_secret_arn" { type = string }
variable "instance_sg_id" { type = string }
variable "alb_sg_id" { type = string }
variable "alb_tg_staging_arn" { type = string }
variable "alb_tg_prod_arn" { type = string }
variable "ecr_repo_url" { type = string }
variable "tags" { type = map(string) }

variable "region" { type = string }
