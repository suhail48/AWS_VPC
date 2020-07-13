provider "aws" {
	region="ap-south-1"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myvpc"
  }
}
resource "aws_subnet" "mysubnet_1a" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "mysubnet_1a"
  }
  depends_on = [
    aws_vpc.myvpc
  ]
}
resource "aws_subnet" "mysubnet_1b" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "mysubnet_1b"
  }
  depends_on = [
    aws_vpc.myvpc
  ]
}
resource "aws_internet_gateway" "my_internet_gw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "my_internet_gw"
  }
  depends_on = [
    aws_vpc.myvpc
  ]
}
resource "aws_route_table" "my_route" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gw.id
  }
  depends_on = [
    aws_internet_gateway.my_internet_gw
  ]

}

resource "aws_route_table_association" "subnet_association-1a" {
  subnet_id      = aws_subnet.mysubnet_1a.id
  route_table_id = aws_route_table.my_route.id
  depends_on = [
    aws_route_table.my_route
  ]
}
resource "aws_main_route_table_association" "subnet-association-main-1a" {
  vpc_id         = aws_vpc.myvpc.id
  route_table_id = aws_route_table.my_route.id
  depends_on = [
    aws_route_table_association.subnet_association-1a
  ]
}

resource "aws_security_group" "WordPressSG" {
  name = "WordPressSG"
  vpc_id = aws_vpc.myvpc.id
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "WordPressSG"
  }
}
 
resource "aws_security_group" "MysqlSG" {
 name = "MysqlSG"
 vpc_id = aws_vpc.myvpc.id
  
  ingress {
    description = "MYSQL-rule"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "MysqlSG"
  }
}
 
resource "aws_instance" "WordPressOS" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.mysubnet_1a.id
  vpc_security_group_ids = [aws_security_group.WordPressSG.id]
  key_name = "ec2_key"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "WordPressOS"
  }
  depends_on = [
    aws_route_table_association.subnet_association-1a,aws_security_group.WordPressSG
  ]
}

resource "aws_instance" "MySqlOS" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet_1b.id
  vpc_security_group_ids = [aws_security_group.MysqlSG.id]
  key_name = "ec2_key"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "MySqlOS"
  }
  depends_on = [
    aws_security_group.MysqlSG
  ]
} 



/*
resource "aws_instance" "my_os_1a" {
	ami= "ami-0447a12f28fddb066"
	instance_type= "t2.micro"
	key_name= "ec2_key"
  security_groups= [aws_security_group.allow.id]
  subnet_id = aws_subnet.mysubnet_1a.id
  tags={
		name= "myos_1a"
	}
  depends_on = [
    aws_route_table_association.subnet_association,aws_security_group.allow
  ]
}
*/
