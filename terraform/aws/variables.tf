variable "region" {
  default = "us-east-1"
}

variable "resource_prefix" {
  default = "epicbook-prod"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "admin_username" {
  default = "ubuntu"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa_mini_finance.pub"
}