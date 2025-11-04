# 1. 定义VPC网络
resource "google_compute_network" "elk_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# 2. 定义子网
resource "google_compute_subnetwork" "elk_subnet" {
  name          = var.subnet_name
  network       = google_compute_network.elk_network.self_link
  region        = var.region
  ip_cidr_range = "10.0.0.0/24"
}

# 3. 定义防火墙规则（开放SSH、ELK端口）
resource "google_compute_firewall" "elk_firewall" {
  name    = "elk-firewall"
  network = google_compute_network.elk_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "9200", "5601", "5044"] # SSH、Elasticsearch、Kibana、Logstash
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["elk-instance"]
}

# 4. 定义Compute Instance
resource "google_compute_instance" "elk_instance" {
  name         = "elk-single-node"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["elk-instance"]

  boot_disk {
    initialize_params {
      # 替换为Ubuntu 22.04 LTS镜像（所有区域通用）
      image = "ubuntu-os-cloud/ubuntu-2204-lts" 
      size  = var.disk_size
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.elk_subnet.self_link
    access_config {
      # 自动分配外部IP
    }
  }

  # 启动脚本：安装ELK（添加日志重定向）
  metadata_startup_script = templatefile("scripts/install-elk.tpl", {
    elk_version = var.elk_version
  })

  # 依赖防火墙规则
  depends_on = [google_compute_firewall.elk_firewall]
}