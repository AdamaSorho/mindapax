# Creates a new security group for the backend EC2 instance
resource "aws_security_group" "backend_ec2" {
  name        = "mindapax-backend-ec2-sg"
  description = "Allow inbound traffic for the backend EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creates a new IAM role for the EC2 instance
resource "aws_iam_role" "ec2" {
  name = "mindapax-ec2-role"

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

# Attaches the AmazonS3ReadOnlyAccess policy to the EC2 role
resource "aws_iam_role_policy_attachment" "ec2_s3_read_only" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Creates a new IAM instance profile for the EC2 instance
resource "aws_iam_instance_profile" "ec2" {
  name = "mindapax-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Creates a new EC2 instance for the backend
resource "aws_instance" "backend" {
  ami           = "ami-08a6efd148b1f7504"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_a.id
  vpc_security_group_ids = [aws_security_group.backend_ec2.id]
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              aws s3 cp s3://mindapax-backend-bucket/mindapax-backend.jar /home/ec2-user/mindapax-backend.jar
              java -jar /home/ec2-user/mindapax-backend.jar
              EOF

  tags = {
    Name = "mindapax-backend"
  }
}
