output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }

output "alb_dns_name" { value = module.alb.alb_dns_name }
output "alb_arn" { value = module.alb.alb_arn }

output "staging_instance_id" { value = module.ec2.staging_instance_id }
output "prod_instance_id" { value = module.ec2.prod_instance_id }

output "ecr_repository_url" { value = aws_ecr_repository.app.repository_url }
output "artifact_bucket" { value = aws_s3_bucket.artifacts.bucket }
output "static_assets_bucket" { value = aws_s3_bucket.static_assets.bucket }
