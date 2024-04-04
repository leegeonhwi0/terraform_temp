
output "srv_alb_name" {
  value = aws_lb.srv_alb.name
}


output "bastion_public_ips" {
  value = aws_instance.bastion_host[*].public_ip
}

output "kube-controller_ips" {
  value = aws_instance.kube-controller[*].private_ip
}

output "kube_worker_ips" {
  value = aws_instance.kube_worker[*].private_ip
}
