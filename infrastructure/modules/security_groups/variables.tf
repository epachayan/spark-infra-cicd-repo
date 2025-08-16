variable "name" { type = string }
variable "vpc_id" { type = string }
variable "allow_ssh_cidrs" { type = list(string) }
variable "tags" { type = map(string) }
