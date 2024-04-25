# Output
output "bastion-pub-ip" {
  value = module.instance.bastion_public_ips
}

output "kube-controller-ip" {
  value = module.instance.kube_controller_ips
}


output "kube-worker-ip" {
  value = module.instance.kube_worker_ips
}

output "haproxy-ip" {
  value = module.instance.haproxy_ips
}

output "db_ip" {
  value = module.instance.db_ips
}

output "kube_nlb_dns" {
  value = module.instance.kube_nlb_dns
}
