# my_vpc
resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my_vpc"
  }
}

# my_public_subnet
resource "aws_subnet" "pub_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "my_public_subnet"
  }
}

# my_private_subnet
resource "aws_subnet" "priv_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "my_private_subnet"
  }
}

# my_public_internet_gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_public_internet_gateway"
  }
}

# my_private_subnet_route_table 
resource "aws_route_table" "priv_rtable" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_private_subnet_route_table"
  }
}

# my_public_subnet_route_table 
resource "aws_route_table" "pub_rtable" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my_public_subnet_route_table"
  }
}


# My public route table association
resource "aws_route_table_association" "my_pub_rtable_asoc" {
  subnet_id      = aws_subnet.pub_subnet.id
  route_table_id = aws_route_table.pub_rtable.id
}

# My private route table association
resource "aws_route_table_association" "my_priv_rtable_asoc" {
  subnet_id      = aws_subnet.priv_subnet.id
  route_table_id = aws_route_table.priv_rtable.id
}


# my_security_group
resource "aws_security_group" "my_sg" {
  name        = "my_sg"
  description = "My security group"
  vpc_id      = aws_vpc.my_vpc.id

  tags = {
    Name = "my_security_group"
  }
}

# my_sg_egress_rule
resource "aws_vpc_security_group_egress_rule" "sg_egress" {
  security_group_id = aws_security_group.my_sg.id

  cidr_ipv4   = "0.0.0.0/0"  
  ip_protocol = "-1"
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  myip = chomp(data.http.myip.response_body)
}

# my_sg_ingress_rules

resource "aws_vpc_security_group_ingress_rule" "ssh_home" {
  security_group_id = aws_security_group.my_sg.id

  cidr_ipv4   = "${local.myip}/32"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.my_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443  
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.my_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# web_portofolio_public_ip
resource "aws_eip" "web_portfolio_eip" {
  domain = "vpc"
  tags = {
    Name = "web_portfolio_eip"
  }  
}

resource "aws_eip_association" "web_portfolio_assoc" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.web_portfolio_eip.id
  depends_on    = [aws_instance.this]
}

resource "aws_route53_zone" "main" {
  name = var.domain_name
  comment = "Public hosted zone for my site"
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.main.zone_id
  name    = ""  # represents the zone apex; point the domain without www to the eip
  type    = "A"
  ttl     = 300
  records = [aws_eip.web_portfolio_eip.public_ip]
}

resource "aws_route53_record" "www" {
  name    = "www"
  zone_id = aws_route53_zone.main.zone_id
  type    = "A"
  ttl     = 300
  records = [aws_eip.web_portfolio_eip.public_ip]
}

resource "aws_iam_role" "ec2_ecr_role" {
  name = "ec2-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AmazonEC2ContainerRegistryReadOnly policy
resource "aws_iam_role_policy_attachment" "ecr_readonly_attach" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create an instance profile for EC2
resource "aws_iam_instance_profile" "ec2_ecr_profile" {
  name = "ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_role.name
}
