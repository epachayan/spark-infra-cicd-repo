variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project/system name used for tagging"
  type        = string
  default     = "saas-example"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  default     = null
  description = "Optional EC2 key pair for emergency SSH access (recommended to keep null)"
}

variable "staging_secret_arn" {
  description = "AWS Secrets Manager ARN for staging environment secret (JSON)."
  type        = string
}

variable "prod_secret_arn" {
  description = "AWS Secrets Manager ARN for production environment secret (JSON)."
  type        = string
}

variable "allow_ssh_cidrs" {
  description = "Optional list of CIDR blocks allowed to SSH to instances (discouraged; use SSM)."
  type        = list(string)
  default     = []
}

variable "ecr_repo_name" {
  description = "ECR repository name for app images."
  type        = string
  default     = "saas-example-app"
}

variable "artifact_bucket_name" {
  description = "S3 bucket for build artifacts and deployment metadata."
  type        = string
  default     = null
}

variable "static_assets_bucket_name" {
  description = "S3 bucket for app static assets."
  type        = string
  default     = null
}

variable "alb_health_check_path" {
  type        = string
  default     = "/health"
}

variable "tags" {
  type        = map(string)
  default     = {}
}
