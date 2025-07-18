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
  # The name of the solution stack to use
  solution_stack_name = "64bit Amazon Linux 2 v3.4.4 running Corretto 17"

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

  # A map of settings to apply to the environment
  setting {
    # The namespace for the setting
    namespace = "aws:elasticbeanstalk:environment"
    # The name of the setting
    name      = "ServiceRole"
    # The value of the setting
    value     = "aws-elasticbeanstalk-service-role"
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
}
