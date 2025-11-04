# 1. 自定义VPC
resource "google_compute_network" "elk_vpc" {
  name                    = "elk-vpc"
  auto_create_subnetworks = false
}

# 2. 子网
resource "google_compute_subnetwork" "elk_subnet" {
  name          = "elk-subnet"
  region        = var.region
  network       = google_compute_network.elk_vpc.id
  ip_cidr_range = "10.0.0.0/24"
}

# 3. 防火墙规则：开放SSH、ELK端口
resource "google_compute_firewall" "elk_fw" {
  name    = "elk-allow-internal"
  network = google_compute_network.elk_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "9200", "5601", "5044"] # SSH、Elasticsearch、Kibana、Logstash
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["elk-single"]
}

# 4. 外部IP
resource "google_compute_address" "elk_ext_ip" {
  name   = "elk-single-ip"
  region = var.region
}

# 5. 计算实例
resource "google_compute_instance" "elk_single" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["elk-single"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.boot_disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.elk_subnet.id
    access_config {
      nat_ip = google_compute_address.elk_ext_ip.address
    }
  }

  # 配置SSH密钥（支持多用户免密登录）
  metadata = {
    ssh-keys = "root:${file(var.ssh_public_key_path)}\nubuntu:${file(var.ssh_public_key_path)}\nelk:${file(var.ssh_public_key_path)}\nlogstash:${file(var.ssh_public_key_path)}\nkibana:${file(var.ssh_public_key_path)}"
  }

  # 启动脚本
  metadata_startup_script = file("${path.module}/scripts/install-elk.sh")

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [google_compute_firewall.elk_fw]
}