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
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*",
        ]
      },
      {
        Action = [
          "elasticbeanstalk:CreateApplicationVersion",
          "elasticbeanstalk:UpdateEnvironment",
        ]
        Effect   = "Allow"
        Resource = [
          aws_elastic_beanstalk_application.backend.arn,
          aws_elastic_beanstalk_environment.backend.arn,
        ]
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
