variable "project_id" {
  description = "GCP项目ID"
  type        = string
}

variable "region" {
  description = "GCP区域"
  type        = string
  default     = "asia-east1"
}

variable "zone" {
  description = "GCP可用区"
  type        = string
  default     = "asia-east1-a"
}

variable "instance_name" {
  description = "ELK实例名称"
  type        = string
  default     = "elk-single-node"
}

variable "machine_type" {
  description = "虚拟机类型（4核8G）"
  type        = string
  default     = "e2-standard-4"
}

variable "boot_disk_size_gb" {
  description = "磁盘大小（GB）"
  type        = number
  default     = 100
}

variable "elk_version" {
  description = "ELK版本"
  type        = string
  default     = "8.10.0"
}

variable "ssh_public_key_path" {
  description = "本地SSH公钥路径"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}