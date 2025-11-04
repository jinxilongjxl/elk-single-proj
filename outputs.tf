output "elk_external_ip" {
  description = "ELK实例外部IP"
  value       = google_compute_instance.elk_instance.network_interface[0].access_config[0].nat_ip
}

output "kibana_url" {
  description = "Kibana访问地址"
  value       = "http://${google_compute_instance.elk_instance.network_interface[0].access_config[0].nat_ip}:5601"
}

output "ssh_command" {
  description = "SSH连接命令"
  value       = "ssh -i ~/.ssh/your-ssh-key ubuntu@${google_compute_instance.elk_instance.network_interface[0].access_config[0].nat_ip}"
}

output "install_log_tip" {
  description = "安装日志查看命令（SSH连接后执行）"
  value       = "sudo cat /var/log/elk-install.log"
}