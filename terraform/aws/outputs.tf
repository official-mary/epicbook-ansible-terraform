output "public_ip" {
  value = aws_eip.main.public_ip
}

output "admin_user" {
  value = var.admin_username
}