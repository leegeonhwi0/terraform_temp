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