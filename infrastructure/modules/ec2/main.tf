data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_iam_role" "instance_role" {
  name               = "${var.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service", identifiers = ["ec2.amazonaws.com"] }
  }
}

# Allow SSM, ECR pulls, and reading specific secrets
data "aws_iam_policy_document" "instance_inline" {
  statement {
    sid = "SSMCore"
    actions = [
      "ssm:DescribeAssociation", "ssm:GetDeployablePatchSnapshotForInstance", "ssm:GetDocument",
      "ssm:DescribeDocument", "ssm:GetManifest", "ssm:GetParameter", "ssm:GetParameters",
      "ssm:ListAssociations", "ssm:ListInstanceAssociations", "ssm:PutInventory",
      "ssm:PutComplianceItems", "ssm:PutConfigurePackageResult", "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus", "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }
  statement {
    sid = "SSMMessage"
    actions = ["ssmmessages:*", "ec2messages:*"]
    resources = ["*"]
  }
  statement {
    sid = "ECRPull"
    actions = ["ecr:GetAuthorizationToken","ecr:BatchGetImage","ecr:GetDownloadUrlForLayer","ecr:BatchCheckLayerAvailability"]
    resources = ["*"]
  }
  statement {
    sid = "SecretsRead"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [var.staging_secret_arn, var.prod_secret_arn]
  }
  statement {
    sid = "CloudWatchLogs"
    actions = ["logs:CreateLogStream","logs:PutLogEvents","logs:CreateLogGroup"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "instance_policy" {
  name   = "${var.name}-ec2-policy"
  policy = data.aws_iam_policy_document.instance_inline.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy_attachment" "attach1" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach2" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.instance_policy.arn
}



# STAGING instance
resource "aws_instance" "staging" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [var.instance_sg_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    region = var.region,
    env_name = "staging"
    image    = "${var.ecr_repo_url}:staging"
    secret_arn = var.staging_secret_arn
    app_port = var.app_port
  }))

  tags = merge(var.tags, { Name = "${var.name}-staging", Environment = "staging" })
}

# PRODUCTION instance
resource "aws_instance" "prod" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[1]
  vpc_security_group_ids = [var.instance_sg_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    region = var.region,
    env_name = "production"
    image    = "${var.ecr_repo_url}:prod"
    secret_arn = var.prod_secret_arn
    app_port = var.app_port
  }))

  tags = merge(var.tags, { Name = "${var.name}-prod", Environment = "production" })
}

# Register instances with target groups
resource "aws_lb_target_group_attachment" "staging_attach" {
  target_group_arn = var.alb_tg_staging_arn
  target_id        = aws_instance.staging.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "prod_attach" {
  target_group_arn = var.alb_tg_prod_arn
  target_id        = aws_instance.prod.id
  port             = 80
}

