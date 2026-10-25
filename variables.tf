variable "cloud_id" {
  type        = string
  default     = "b1gj3qbamvs4h8r8keio" 
}

variable "folder_id" {
  type        = string
  default     = "b1g9af9fe1gsnt7r0n36" 
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
}

variable "ubuntu_2404_family" {
  type        = string
  default     = "ubuntu-2404-lts"
}

# Распределяем машины по трем разным дата-центрам Яндекса
variable "k8s_nodes" {
  type = map(object({
    cores  = number
    memory = number
    zone   = string
  }))
  default = {
    "master-1" = { cores = 2, memory = 2, zone = "ru-central1-d" }
    "worker-1" = { cores = 2, memory = 2, zone = "ru-central1-e" }
    "worker-2" = { cores = 2, memory = 2, zone = "ru-central1-d" } # <--- Переносим в зону D
    "worker-3" = { cores = 2, memory = 2, zone = "ru-central1-e" } # <--- Переносим в зону E
  }
}
