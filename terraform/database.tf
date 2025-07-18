# Creates a database subnet group for the RDS instance
resource "aws_db_subnet_group" "default" {
  # The name of the database subnet group
  name       = "mindapax-db-subnet-group"
  # A list of subnet IDs to associate with the database subnet group
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # A map of tags to assign to the resource
  tags = {
    Name = "Mindapax DB subnet group"
  }
}

# Creates a new RDS instance
resource "aws_db_instance" "default" {
  # The amount of storage to allocate for the database instance
  allocated_storage    = 20
  # The name of the database engine to use
  engine               = "mysql"
  # The version of the database engine to use
  engine_version       = "8.0"
  # The instance type to use for the database instance
  instance_class       = "db.t2.micro"
  # The name of the database to create when the instance is created
  db_name                 = "mindapax"
  # The username for the master user
  username             = "admin"
  # The password for the master user
  password             = var.db_password
  # The name of the database subnet group to associate with the instance
  db_subnet_group_name = aws_db_subnet_group.default.name
  # A list of VPC security group IDs to associate with the instance
  vpc_security_group_ids = [aws_security_group.database.id]
  # Determines whether a final snapshot is created before the instance is deleted
  skip_final_snapshot  = true
}
