
output "srv_alb_name" {
  value = aws_lb.srv_alb.name
}


output "bastion_public_ips" {
  value = aws_instance.bastion_host[*].public_ip
}

output "kube_controller_ips" {
  value = aws_instance.kube_controller[*].private_ip
}

output "kube_controller_ips_c" {
  value = aws_instance.kube_controller_c[*].private_ip
}

output "kube_worker_ips" {
  value = aws_instance.kube_worker[*].private_ip
}

output "kube_worker_ips_c" {
  value = aws_instance.kube_worker_c[*].private_ip
}

output "haproxy1_ips" {
  value = aws_instance.haproxy1[*].private_ip
}

output "haproxy2_ips" {
  value = aws_instance.haproxy2[*].private_ip
}