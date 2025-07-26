# Creates a new Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "backend" {
  # The name of the application
  name        = "mindapax-backend"
  # A description of the application
  description = "Mindapax backend application"
}

# Creates a new Elastic Beanstalk environment
resource "aws_elastic_beanstalk_environment" "backend" {
  # The name of the environment
  name                = "mindapax-backend-env"
  # The name of the application to associate the environment with
  application         = aws_elastic_beanstalk_application.backend.name
  # The name of the solution stack to use - Updated to Amazon Linux 2023
  solution_stack_name = "64bit Amazon Linux 2023 v4.6.1 running Corretto 17"

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:ec2:vpc"
    # The name of the setting
    name      = "VPCId"
    # The value of the setting
    value     = aws_vpc.main.id
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:ec2:vpc"
    # The name of the setting
    name      = "Subnets"
    # The value of the setting
    value     = "${aws_subnet.private_a.id},${aws_subnet.private_b.id}"
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:ec2:vpc"
    # The name of the setting
    name      = "ELBSubnets"
    # The value of the setting
    value     = "${aws_subnet.public_a.id},${aws_subnet.public_b.id}"
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:ec2:vpc"
    # The name of the setting
    name      = "AssociatePublicIpAddress"
    # The value of the setting
    value     = "false"
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:autoscaling:launchconfiguration"
    # The name of the setting
    name      = "InstanceType"
    # The value of the setting
    value     = "t2.micro"
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:autoscaling:launchconfiguration"
    # The name of the setting
    name      = "SecurityGroups"
    # The value of the setting
    value     = aws_security_group.backend.id
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:elasticbeanstalk:environment"
    # The name of the setting
    name      = "LoadBalancerType"
    # The value of the setting
    value     = "application"
  }

  # Use the service role for Elastic Beanstalk operations
  setting {
    # The namespace for the setting
    namespace = "aws:elasticbeanstalk:environment"
    # The name of the setting
    name      = "ServiceRole"
    # The value of the setting
    value     = aws_iam_role.beanstalk_service.arn
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:elasticbeanstalk:environment:proxy:staticfiles"
    # The name of the setting
    name      = "/static"
    # The value of the setting
    value     = "static"
  }

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:autoscaling:launchconfiguration"
    # The name of the setting
    name      = "IamInstanceProfile"
    # The value of the setting
    value     = aws_iam_instance_profile.beanstalk.name
  }

  # Environment variables
  setting {
    # The namespace for the setting
    namespace = "aws:elasticbeanstalk:application:environment"
    # The name of the setting
    name      = "ZOOM_SECRET_KEY"
    # The value of the setting
    value     = var.zoom_secret_key
  }

  setting {
    # The namespace for the setting
    namespace = "aws:elasticbeanstalk:application:environment"
    # The name of the setting
    name      = "ZOOM_SDK_KEY"
    # The value of the setting
    value     = var.zoom_sdk_key
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "DB_NAME"
    value = aws_db_instance.default.db_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MYSQL_USER"
    value = aws_db_instance.default.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MYSQL_PASSWORD"
    value = aws_db_instance.default.password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MYSQL_HOST"
    value = aws_db_instance.default.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MYSQL_PORT"
    value = aws_db_instance.default.port
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "MYSQL_ROOT_PASSWORD"
    value = aws_db_instance.default.password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "ZOOM_API_ACCOUNT_ID"
    value = var.zoom_api_account_id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "ZOOM_API_CLIENT_ID"
    value = var.zoom_api_client_id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "ZOOM_API_CLIENT_SECRET"
    value = var.zoom_api_client_secret
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "JWT_SECRET"
    value = var.jwt_secret
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "JWT_EXPIRATION_TIME"
    value = var.jwt_expiration_time
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "JWT_REFRESH_TOKEN_EXPIRATION_MS"
    value = var.jwt_refresh_token_expiration_ms
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "SPRING_PROFILES_ACTIVE"
    value = var.spring_profiles_active
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "AWS_REGION"
    value = var.aws_region
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name = "AWS_S3_BUCKET_NAME"
    value = var.aws_s3_bucket_name
  }
}