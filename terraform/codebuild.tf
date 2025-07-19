resource "aws_codebuild_source_credential" "github_token" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_token
}

# Creates a new CodeBuild project for the frontend
resource "aws_codebuild_project" "frontend" {
  # The name of the project
  name          = "mindapax-frontend"
  # A description of the project
  description   = "Builds and deploys the Mindapax frontend"
  # The ARN of the service role to use
  service_role  = aws_iam_role.codebuild.arn

  # The source for the build project
  source {
    # The type of the source
    type      = "GITHUB"
    # The location of the source
    location  = "https://github.com/AdamaSorho/mindapax.git"
    # The type of the buildspec
    buildspec = "mindapax-frontend/buildspec.yml"
    # The source credential to use
    source_credential {
      arn = aws_codebuild_source_credential.github_token.arn
    }
  }

  # The environment for the build project
  environment {
    # The type of the environment
    type          = "LINUX_CONTAINER"
    # The image to use for the environment
    image         = "aws/codebuild/standard:5.0"
    # The compute type to use for the environment
    compute_type  = "BUILD_GENERAL1_SMALL"
  }

  # The artifacts for the build project
  artifacts {
    # The type of the artifacts
    type = "NO_ARTIFACTS"
  }
}

# Creates a new CodeBuild project for the backend
resource "aws_codebuild_project" "backend" {
  # The name of the project
  name          = "mindapax-backend"
  # A description of the project
  description   = "Builds and deploys the Mindapax backend"
  # The ARN of the service role to use
  service_role  = aws_iam_role.codebuild.arn

  # The source for the build project
  source {
    # The type of the source
    type      = "GITHUB"
    # The location of the source
    location  = "https://github.com/AdamaSorho/mindapax.git"
    # The type of the buildspec
    buildspec = "mindapax-backend/buildspec.yml"
    # The source credential to use
    source_credential {
      arn = aws_codebuild_source_credential.github_token.arn
    }
  }

  # The environment for the build project
  environment {
    # The type of the environment
    type          = "LINUX_CONTAINER"
    # The image to use for the environment
    image         = "aws/codebuild/standard:5.0"
    # The compute type to use for the environment
    compute_type  = "BUILD_GENERAL1_SMALL"
  }

  # The artifacts for the build project
  artifacts {
    # The type of the artifacts
    type = "NO_ARTIFACTS"
  }
}
