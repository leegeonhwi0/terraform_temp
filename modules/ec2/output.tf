
output "srv_alb_name" {
  value = aws_lb.srv_alb.name
}


output "bastion_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "ans_srv_pvt_ip" {
  value = aws_instance.ansible_server.private_ip
}

output "ansible_nod_ips" {
  value = aws_instance.ansible_nod[*].private_ip
}
