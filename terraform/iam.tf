# Creates a new IAM role for CodeBuild
resource "aws_iam_role" "codebuild" {
  # The name of the role
  name = "mindapax-codebuild-role"

  # The policy that grants permission to assume the role
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# Creates a new IAM policy for CodeBuild
resource "aws_iam_policy" "codebuild" {
  # The name of the policy
  name = "mindapax-codebuild-policy"

  # The policy document
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:CreateBucket",
          "s3:PutBucketOwnershipControls",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketPolicyStatus",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*",
          aws_s3_bucket.backend.arn,
          "${aws_s3_bucket.backend.arn}/*",
          "arn:aws:s3:::elasticbeanstalk-us-east-1-*",
          "arn:aws:s3:::elasticbeanstalk-us-east-1-*/*"
        ]
      },
      {
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListDistributions"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "elasticbeanstalk:CreateApplicationVersion",
          "elasticbeanstalk:UpdateEnvironment",
          "elasticbeanstalk:DescribeEnvironments",
          "elasticbeanstalk:DescribeConfigurationSettings",
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "autoscaling:DescribeAutoScalingGroups",
          "cloudformation:DescribeStacks",
          "cloudformation:GetTemplate",
          "cloudformation:DescribeStackResource",
          "cloudformation:DescribeStackResources",
          "ec2:CreateLaunchTemplate"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Attaches the policy to the role
resource "aws_iam_role_policy_attachment" "codebuild" {
  # The name of the role to attach the policy to
  role       = aws_iam_role.codebuild.name
  # The ARN of the policy to attach
  policy_arn = aws_iam_policy.codebuild.arn
}

# Creates a new IAM role for the Elastic Beanstalk environment
resource "aws_iam_role" "beanstalk" {
  name = "mindapax-beanstalk-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Creates a new IAM service role for Elastic Beanstalk service operations
resource "aws_iam_role" "beanstalk_service" {
  name = "mindapax-elasticbeanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the Elastic Beanstalk service role policy
resource "aws_iam_role_policy_attachment" "beanstalk_service" {
  role       = aws_iam_role.beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# Attach enhanced health policy for the service role
resource "aws_iam_role_policy_attachment" "beanstalk_enhanced_health" {
  role       = aws_iam_role.beanstalk_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

# Attach the necessary managed policies for Elastic Beanstalk EC2 instances
resource "aws_iam_role_policy_attachment" "beanstalk_web_tier" {
  role       = aws_iam_role.beanstalk.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_worker_tier" {
  role       = aws_iam_role.beanstalk.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_multicontainer_docker" {
  role       = aws_iam_role.beanstalk.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

# Custom policy for comprehensive S3 access including AWS-managed Elastic Beanstalk resources
resource "aws_iam_policy" "beanstalk_s3_access" {
  name = "mindapax-beanstalk-s3-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::elasticbeanstalk-*",
          "arn:aws:s3:::elasticbeanstalk-*/*",
          # Include the actual bucket in your account
          "arn:aws:s3:::elasticbeanstalk-us-east-1-*",
          "arn:aws:s3:::elasticbeanstalk-us-east-1-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::elasticbeanstalk-*/*",
          "arn:aws:s3:::elasticbeanstalk-us-east-1-*/*"
        ]
      },
      {
        # Additional permissions for SSM and Systems Manager operations
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeInstanceInformation",
          "ssm:DescribeInstanceProperties",
          "ssm:DescribeDocumentParameters",
          "ssm:ListDocuments",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the S3 access policy to the instance role
resource "aws_iam_role_policy_attachment" "beanstalk_s3_access" {
  role       = aws_iam_role.beanstalk.name
  policy_arn = aws_iam_policy.beanstalk_s3_access.arn
}

# Attach SSM managed instance core policy for patching operations
resource "aws_iam_role_policy_attachment" "beanstalk_ssm_managed_instance_core" {
  role       = aws_iam_role.beanstalk.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Remove or comment out the managed updates policy attachment as it may be causing issues
# resource "aws_iam_role_policy_attachment" "beanstalk_managed_updates" {
#   role       = aws_iam_role.beanstalk.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
# }

# Creates a new IAM instance profile for the Elastic Beanstalk environment
resource "aws_iam_instance_profile" "beanstalk" {
  name = "mindapax-beanstalk-profile"
  role = aws_iam_role.beanstalk.name
}