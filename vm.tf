# Key pair for SSH access
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my_key_pair"
  public_key = var.ssh_public_key
}

resource "aws_instance" "this" {
  ami           = "ami-0bbdd8c17ed981ef9" # Ubuntu 22.04
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pub_subnet.id
  key_name      = aws_key_pair.my_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_ecr_profile.name

  user_data = file("userdata.tpl")

  tags = {
    Name = "MyWebPortofolioServer"
  }
}

