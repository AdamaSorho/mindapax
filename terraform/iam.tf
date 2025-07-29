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
