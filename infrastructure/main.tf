locals {
  name = var.project_name
  tags = merge(var.tags, { Project = var.project_name })
}

module "vpc" {
  source          = "./modules/vpc"
  name            = local.name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  tags            = local.tags
}

module "sg" {
  source = "./modules/security_groups"
  name   = local.name
  vpc_id = module.vpc.vpc_id

  allow_ssh_cidrs = var.allow_ssh_cidrs
  tags            = local.tags
}

module "alb" {
  source                 = "./modules/alb"
  name                   = local.name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  alb_sg_id              = module.sg.alb_sg_id
  staging_tg_name        = "${local.name}-staging-tg"
  prod_tg_name           = "${local.name}-prod-tg"
  health_check_path      = var.alb_health_check_path
  tags                   = local.tags
}

resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = local.tags
}

# S3 buckets
resource "aws_s3_bucket" "artifacts" {
  bucket = coalesce(var.artifact_bucket_name, "${local.name}-artifacts-${random_id.suffix.hex}")
  force_destroy = true
  tags = local.tags
}
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "static_assets" {
  bucket = coalesce(var.static_assets_bucket_name, "${local.name}-static-${random_id.suffix.hex}")
  force_destroy = true
  tags = local.tags
}
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_id" "suffix" { byte_length = 4 }

module "ec2" {\n  region                 = var.region
  source                 = "./modules/ec2"
  name                   = local.name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  instance_type          = var.instance_type
  key_name               = var.key_name
  app_port               = 80
  staging_secret_arn     = var.staging_secret_arn
  prod_secret_arn        = var.prod_secret_arn
  instance_sg_id         = module.sg.instance_sg_id
  alb_sg_id              = module.sg.alb_sg_id
  alb_tg_staging_arn     = module.alb.staging_tg_arn
  alb_tg_prod_arn        = module.alb.prod_tg_arn
  ecr_repo_url           = aws_ecr_repository.app.repository_url
  tags                   = local.tags
}
