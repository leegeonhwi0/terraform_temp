output "kubecluster_sg_id" {
  value = aws_security_group.kube_cluster_sg.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}
