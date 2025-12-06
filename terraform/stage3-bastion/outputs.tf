###################################
# Bastion
###################################

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion_sg.id
}