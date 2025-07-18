# Creates a new secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  # The name of the secret
  name = "mindapax/db_password"
}

# Creates a new version of the secret
resource "aws_secretsmanager_secret_version" "db_password" {
  # The ARN of the secret to add the version to
  secret_id     = aws_secretsmanager_secret.db_password.id
  # The secret value to store in the new version
  secret_string = var.db_password
}

# Creates a new secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "zoom_secret_key" {
  # The name of the secret
  name = "mindapax/zoom_secret_key"
}

# Creates a new version of the secret
resource "aws_secretsmanager_secret_version" "zoom_secret_key" {
  # The ARN of the secret to add the version to
  secret_id     = aws_secretsmanager_secret.zoom_secret_key.id
  # The secret value to store in the new version
  secret_string = "your-zoom-secret-key"
}
