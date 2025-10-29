variable "access_key" {
  description = "My access key"
  type        = string
}

variable "secret_key" {
  description = "My secret key"
  type        = string
}

variable "ssh_public_key" {
  description = "My ssh public key"
  type        = string  
}

variable "domain_name" {
  description = "My domain name name"
  type        = string  
}

variable "email" {
  description = "My email"
  type        = string  
}

variable "docker_image"{
  description = "The uri of the docker image"
  type        = string  
}