output "elk_external_ip" {
  description = "ELK实例外部IP"
  value       = google_compute_address.elk_ext_ip.address
}

output "kibana_url" {
  description = "Kibana访问地址"
  value       = "http://${google_compute_address.elk_ext_ip.address}:5601"
}

output "ssh_root_login" {
  description = "root用户SSH登录命令"
  value       = "ssh -i ~/.ssh/id_ed25519 root@${google_compute_address.elk_ext_ip.address}"
}

output "ssh_ubuntu_login" {
  description = "ubuntu用户SSH登录命令"
  value       = "ssh -i ~/.ssh/id_ed25519 ubuntu@${google_compute_address.elk_ext_ip.address}"
}

output "ssh_elk_login" {
  description = "elk用户SSH登录命令"
  value       = "ssh -i ~/.ssh/id_ed25519 elk@${google_compute_address.elk_ext_ip.address}"
}

output "ssh_logstash_login" {
  description = "logstash用户SSH登录命令"
  value       = "ssh -i ~/.ssh/id_ed25519 logstash@${google_compute_address.elk_ext_ip.address}"
}

output "ssh_kibana_login" {
  description = "kibana用户SSH登录命令"
  value       = "ssh -i ~/.ssh/id_ed25519 kibana@${google_compute_address.elk_ext_ip.address}"
}

output "install_log_tip" {
  description = "安装日志查看命令"
  value       = "ssh -i ~/.ssh/id_ed25519 ubuntu@${google_compute_address.elk_ext_ip.address} 'sudo cat /var/log/install-elk.log'"
}