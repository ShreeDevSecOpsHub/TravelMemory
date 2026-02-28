# ====================================================================
# Security Hardening Configuration for TravelMemory Infrastructure
# ====================================================================

# CloudTrail for Audit Logging
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]

  tags = {
    Name = "${var.project_name}-audit-trail"
  }
}

# S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket_prefix = "${var.project_name}-cloudtrail-logs-"
  force_destroy = false

  tags = {
    Name = "${var.project_name}-cloudtrail-bucket"
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Block Public Access
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail S3 Bucket Policy
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project_name}/application"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-app-logs"
  }
}

# CloudWatch Log Group for System Logs
resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/${var.project_name}/system"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-system-logs"
  }
}

# SNS Topic for Security Alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-security-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "security_alerts" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}

# Enhanced Security Group Rules - Web Server
resource "aws_security_group_rule" "web_ssh_restricted" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.allowed_ssh_cidr
  security_group_id = aws_security_group.web_sg.id
  description       = "SSH access - restricted to allowed CIDR"
}

resource "aws_security_group_rule" "web_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
  description       = "HTTP traffic"
}

resource "aws_security_group_rule" "web_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
  description       = "HTTPS traffic (for future SSL/TLS)"
}

resource "aws_security_group_rule" "web_app_backend" {
  type              = "ingress"
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
  description       = "Backend API traffic"
}

resource "aws_security_group_rule" "web_app_frontend" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_sg.id
  description       = "Frontend React application"
}

resource "aws_security_group_rule" "web_deny_all_other" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.web_sg.id
  description       = "Restricted egress to internal VPC only (can be expanded as needed)"
}

# Enhanced Security Group Rules - Database Server
resource "aws_security_group_rule" "db_mongodb_from_web" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_sg.id
  security_group_id        = aws_security_group.db_sg.id
  description              = "MongoDB access from web server only"
}

resource "aws_security_group_rule" "db_ssh_restricted" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.private_subnet_cidr]
  security_group_id = aws_security_group.db_sg.id
  description       = "SSH from VPC private subnet only"
}

# AWS Secrets Manager for SSH Private Key
resource "aws_secretsmanager_secret" "ssh_private_key" {
  name                    = "${var.project_name}/ssh-key"
  description             = "SSH private key for EC2 instances"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-ssh-key"
  }
}

# EC2 Instance Metadata Options for IMDSv2 (preventing SSRF attacks)
# Note: This is applied at instance level in ec2_instances.tf

# Key Pair Authentication (ensure it exists)
resource "aws_key_pair" "deployment" {
  key_name   = var.key_pair_name
  public_key = file("${path.module}/../${var.key_pair_name}.pub")

  tags = {
    Name = "${var.project_name}-deployment-key"
  }
}

# Enhanced IAM Policy for EC2 with CloudWatch and Secrets Manager
resource "aws_iam_role_policy" "ec2_enhanced_policy" {
  name = "${var.project_name}-ec2-enhanced-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.ssh_private_key.arn,
          "${aws_secretsmanager_secret.ssh_private_key.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# VPC Flow Logs for Network Monitoring
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# AWS Config for Compliance Monitoring
resource "aws_config_configuration_aggregator" "main" {
  name = "${var.project_name}-aggregator"

  account_aggregation_sources {
    all_regions = true
    account_ids = [data.aws_caller_identity.current.account_id]
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
