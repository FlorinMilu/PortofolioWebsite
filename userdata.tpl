#!/bin/bash
# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker and AWS CLI
sudo apt-get install -y docker.io awscli
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Install Certbot
sudo apt-get install -y certbot

# Stop any service using port 80
sudo systemctl stop nginx
sudo systemctl disable nginx
sudo systemctl stop docker

# Obtain SSL certs (non-interactive)
sudo certbot certonly --standalone --non-interactive --agree-tos \
-m ${var.email} \
-d ${var.domain_name} -d www.${var.domain_name}

# Copy certs to a container-readable location
sudo mkdir -p /home/ubuntu/certs
sudo cp /etc/letsencrypt/live/${var.domain_name}/fullchain.pem /home/ubuntu/certs/
sudo cp /etc/letsencrypt/live/${var.domain_name}/privkey.pem /home/ubuntu/certs/
sudo chmod 644 /home/ubuntu/certs/*.pem

# Start Docker
sudo systemctl start docker

# Login to AWS ECR using IAM role credentials
aws ecr get-login-password --region us-east-1 | sudo docker login \
--username AWS \
--password-stdin 162452196343.dkr.ecr.us-east-1.amazonaws.com

# Pull and run container using copied certs
sudo docker pull ${var.docker_image}
sudo docker run -d -p 80:80 -p 443:443 \
    -v /home/ubuntu/certs:/etc/letsencrypt/live/${var.domain_name}:ro \
    ${var.docker_image}