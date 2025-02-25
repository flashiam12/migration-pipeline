data "aws_kms_alias" "secretmanager" {
  name = "alias/aws/secretsmanager"
}

resource "aws_iam_role" "secrets_manager_role" {
  name = "SecretsManagerAccessRole"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "rds.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
})
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "SecretsManagerAccessPolicy"
  description = "Policy for full access to Secrets Manager secrets"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GetSecretValue",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Effect": "Allow",
            "Resource": [
                aws_secretsmanager_secret.rds_secret.arn
            ]
        },
        {
            "Sid": "DecryptSecretValue",
            "Action": [
                "kms:Decrypt"
            ],
            "Effect": "Allow",
            "Resource": [
                data.aws_kms_alias.secretmanager.target_key_arn
            ],
            "Condition": {
                "StringEquals": {
                    "kms:ViaService": "secretsmanager.us-west-2.amazonaws.com"
                }
            }
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "attach_secrets_manager_policy" {
  role       = aws_iam_role.secrets_manager_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# Create a Secrets Manager secret
resource "aws_secretsmanager_secret" "rds_secret" {
  name        = "rds-${var.aws_rds_mysql_instance_name}-proxy-creds"
  description = "RDS database credentials"
}

# Create the version of the secret with the RDS username and password
resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.aws_rds_mysql_user  # Replace with your RDS username
    password = var.aws_rds_mysql_password   # Replace with your RDS password
    engine = "mysql"
    host = data.aws_db_instance.default.address
    port = data.aws_db_instance.default.port
    dbInstanceIdentifier = data.aws_db_instance.default.db_instance_identifier
  })
}

resource "aws_db_proxy" "default" {
  name                   = "${var.aws_rds_mysql_instance_name}-nlb"
  debug_logging          = true
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800
  require_tls            = false
  role_arn               = aws_iam_role.secrets_manager_role.arn
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  vpc_subnet_ids         = [for subnet in data.aws_subnet.default: subnet.id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_secret.arn
    client_password_auth_type = "MYSQL_NATIVE_PASSWORD"
  }

  tags = {
    Purpose  = "eap-test"
    DB = var.aws_rds_mysql_instance_name
  }
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.default.name
}

resource "aws_db_proxy_target" "default" {
  db_instance_identifier = data.aws_db_instance.default.db_instance_identifier
  db_proxy_name          = aws_db_proxy.default.name
  target_group_name      = aws_db_proxy_default_target_group.default.name
}