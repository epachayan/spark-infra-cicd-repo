
#!/bin/bash
set -euo pipefail
dnf update -y
dnf install -y docker git jq awscli
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user || true

mkdir -p /opt/app
cat >/usr/local/bin/deploy_app.sh <<'EOS'
#!/bin/bash
set -euo pipefail
ENV_NAME="$1"
IMAGE="$2"   # e.g. <acct>.dkr.ecr.<region>.amazonaws.com/repo:staging
SECRET_ARN="$3"
APP_PORT="${4:-80}"

# Login to ECR
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin "$(echo "$IMAGE" | cut -d'/' -f1)"

# Pull secrets and write .env
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text)
echo "$SECRET_JSON" | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' >/opt/app/.env

# Pull and run image
docker pull "$IMAGE"
docker rm -f app || true
docker run -d --name app --env-file /opt/app/.env -p 80:3000 "$IMAGE"
echo "Deployed $IMAGE to $ENV_NAME"
EOS
chmod +x /usr/local/bin/deploy_app.sh

# First boot: deploy placeholder tag (staging/prod) so health checks pass.
/usr/local/bin/deploy_app.sh "${env_name}" "${image}" "${secret_arn}" "${app_port}" || echo "Initial deploy skipped"
