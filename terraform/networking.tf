# Creates a new VPC
resource "aws_vpc" "main" {
  # The CIDR block for the VPC
  cidr_block = "10.0.0.0/16"

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-vpc"
  }
}

# Creates a new public subnet in the specified availability zone
resource "aws_subnet" "public_a" {
  # The ID of the VPC to create the subnet in
  vpc_id                  = aws_vpc.main.id
  # The CIDR block for the subnet
  cidr_block              = "10.0.1.0/24"
  # The availability zone to create the subnet in
  availability_zone       = "us-east-1a"
  # Whether to map public IPs to instances in the subnet
  map_public_ip_on_launch = true

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-public-subnet-a"
  }
}

# Creates a new public subnet in the specified availability zone
resource "aws_subnet" "public_b" {
  # The ID of the VPC to create the subnet in
  vpc_id                  = aws_vpc.main.id
  # The CIDR block for the subnet
  cidr_block              = "10.0.2.0/24"
  # The availability zone to create the subnet in
  availability_zone       = "us-east-1b"
  # Whether to map public IPs to instances in the subnet
  map_public_ip_on_launch = true

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-public-subnet-b"
  }
}

# Creates a new private subnet in the specified availability zone
resource "aws_subnet" "private_a" {
  # The ID of the VPC to create the subnet in
  vpc_id            = aws_vpc.main.id
  # The CIDR block for the subnet
  cidr_block        = "10.0.3.0/24"
  # The availability zone to create the subnet in
  availability_zone = "us-east-1a"

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-private-subnet-a"
  }
}

# Creates a new private subnet in the specified availability zone
resource "aws_subnet" "private_b" {
  # The ID of the VPC to create the subnet in
  vpc_id            = aws_vpc.main.id
  # The CIDR block for the subnet
  cidr_block        = "10.0.4.0/24"
  # The availability zone to create the subnet in
  availability_zone = "us-east-1b"

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-private-subnet-b"
  }
}

# Creates a new internet gateway
resource "aws_internet_gateway" "main" {
  # The ID of the VPC to attach the internet gateway to
  vpc_id = aws_vpc.main.id

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-igw"
  }
}

# Creates a new route table for the public subnets
resource "aws_route_table" "public" {
  # The ID of the VPC to create the route table in
  vpc_id = aws_vpc.main.id

  # A list of routes to create in the route table
  route {
    # The CIDR block for the route
    cidr_block = "0.0.0.0/0"
    # The ID of the internet gateway to route traffic to
    gateway_id = aws_internet_gateway.main.id
  }

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-public-rt"
  }
}

# Associates a subnet with a route table
resource "aws_route_table_association" "public_a" {
  # The ID of the subnet to associate with the route table
  subnet_id      = aws_subnet.public_a.id
  # The ID of the route table to associate with the subnet
  route_table_id = aws_route_table.public.id
}

# Associates a subnet with a route table
resource "aws_route_table_association" "public_b" {
  # The ID of the subnet to associate with the route table
  subnet_id      = aws_subnet.public_b.id
  # The ID of the route table to associate with the subnet
  route_table_id = aws_route_table.public.id
}

# Creates a new Elastic IP address
resource "aws_eip" "nat" {
  tags = {
    Name = "mindapax-nat-eip"
  }
}

# Creates a new NAT gateway
resource "aws_nat_gateway" "main" {
  # The ID of the EIP to associate with the NAT gateway
  allocation_id = aws_eip.nat.id
  # The ID of the subnet to create the NAT gateway in
  subnet_id     = aws_subnet.public_a.id

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-nat-gw"
  }
}

# Creates a new route table for the private subnets
resource "aws_route_table" "private" {
  # The ID of the VPC to create the route table in
  vpc_id = aws_vpc.main.id

  # A list of routes to create in the route table
  route {
    # The CIDR block for the route
    cidr_block     = "0.0.0.0/0"
    # The ID of the NAT gateway to route traffic to
    nat_gateway_id = aws_nat_gateway.main.id
  }

  # A map of tags to assign to the resource
  tags = {
    Name = "mindapax-private-rt"
  }
}

# Associates a subnet with a route table
resource "aws_route_table_association" "private_a" {
  # The ID of the subnet to associate with the route table
  subnet_id      = aws_subnet.private_a.id
  # The ID of the route table to associate with the subnet
  route_table_id = aws_route_table.private.id
}

# Associates a subnet with a route table
resource "aws_route_table_association" "private_b" {
  # The ID of the subnet to associate with the route table
  subnet_id      = aws_subnet.private_b.id
  # The ID of the route table to associate with the subnet
  route_table_id = aws_route_table.private.id
}

# Creates a new security group for the load balancer
resource "aws_security_group" "lb" {
  # The name of the security group
  name        = "mindapax-lb-sg"
  # A description of the security group
  description = "Allow HTTP and HTTPS traffic to load balancer"
  # The ID of the VPC to create the security group in
  vpc_id      = aws_vpc.main.id

  # A list of ingress rules to create in the security group
  ingress {
    # The starting port for the rule
    from_port   = 80
    # The ending port for the rule
    to_port     = 80
    # The protocol for the rule
    protocol    = "tcp"
    # A list of CIDR blocks to allow traffic from
    cidr_blocks = ["0.0.0.0/0"]
  }

  # A list of ingress rules to create in the security group
  ingress {
    # The starting port for the rule
    from_port   = 443
    # The ending port for the rule
    to_port     = 443
    # The protocol for the rule
    protocol    = "tcp"
    # A list of CIDR blocks to allow traffic from
    cidr_blocks = ["0.0.0.0/0"]
  }

  # A list of egress rules to create in the security group
  egress {
    # The starting port for the rule
    from_port   = 0
    # The ending port for the rule
    to_port     = 0
    # The protocol for the rule
    protocol    = "-1"
    # A list of CIDR blocks to allow traffic to
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creates a new security group for the backend application
resource "aws_security_group" "backend" {
  # The name of the security group
  name        = "mindapax-backend-sg"
  # A description of the security group
  description = "Allow traffic from load balancer to backend"
  # The ID of the VPC to create the security group in
  vpc_id      = aws_vpc.main.id

  # A list of ingress rules to create in the security group
  ingress {
    # The starting port for the rule
    from_port       = 8080
    # The ending port for the rule
    to_port         = 8080
    # The protocol for the rule
    protocol        = "tcp"
    # A list of security group IDs to allow traffic from
    security_groups = [aws_security_group.lb.id]
  }

  # A list of egress rules to create in the security group
  egress {
    # The starting port for the rule
    from_port   = 0
    # The ending port for the rule
    to_port     = 0
    # The protocol for the rule
    protocol    = "-1"
    # A list of CIDR blocks to allow traffic to
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creates a new security group for the database
resource "aws_security_group" "database" {
  # The name of the security group
  name        = "mindapax-database-sg"
  # A description of the security group
  description = "Allow traffic from backend to database"
  # The ID of the VPC to create the security group in
  vpc_id      = aws_vpc.main.id

  # A list of ingress rules to create in the security group
  ingress {
    # The starting port for the rule
    from_port       = 3306
    # The ending port for the rule
    to_port         = 3306
    # The protocol for the rule
    protocol        = "tcp"
    # A list of security group IDs to allow traffic from
    security_groups = [aws_security_group.backend.id]
  }

  # A list of egress rules to create in the security group
  egress {
    # The starting port for the rule
    from_port   = 0
    # The ending port for the rule
    to_port     = 0
    # The protocol for the rule
    protocol    = "-1"
    # A list of CIDR blocks to allow traffic to
    cidr_blocks = ["0.0.0.0/0"]
  }
}
