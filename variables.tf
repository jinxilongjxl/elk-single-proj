variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP可用区"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "虚拟机类型"
  type        = string
  default     = "e2-medium" # 2vCPU + 4GB内存，适合测试
}

variable "disk_size" {
  description = "磁盘大小（GB）"
  type        = number
  default     = 50
}

variable "elk_version" {
  description = "ELK版本"
  type        = string
  default     = "8.10.0"
}

variable "network_name" {
  description = "VPC网络名称"
  type        = string
  default     = "elk-network"
}

variable "subnet_name" {
  description = "子网名称"
  type        = string
  default     = "elk-subnet"
}