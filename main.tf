output "ec2_public_ip" {
  value = aws_instance.taskhub_server.public_ip
}

### aws custom VPC
resource "aws_vpc" "taskhub_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "taskhub_vpc"
  }
}

### public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.taskhub_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "taskhub-public-subnet"
  }
}

### Internet Gateway

resource "aws_internet_gateway" "taskhub_igw" {
  vpc_id = aws_vpc.taskhub_vpc.id

  tags = {
    Name = "taskhub-igw"
  }
}

### public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.taskhub_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.taskhub_igw.id
  }

  tags = {
    Name = "taskhub-public-route-table"
  }
}

### A route table association
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

### Security Group
resource "aws_security_group" "taskhub_sg" {
  name        = "taskhub-security-group"
  description = "Security group for TaskHub"
  vpc_id      = aws_vpc.taskhub_vpc.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["105.119.1.239/32"]
  }

  ingress {
    description = "Frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  ingress {
    description = "Backend"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskhub-security-group"
  }
}



resource "aws_instance" "taskhub_server" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t3.micro"

  key_name = "aws-key-pair"

  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.taskhub_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "taskhub-server"
  }
}
