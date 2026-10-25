data "yandex_compute_image" "ubuntu_2404" {
  family = var.ubuntu_2404_family
}

# Создание виртуальных машин
resource "yandex_compute_instance" "k8s_node" {
  for_each    = var.k8s_nodes
  name        = each.key
  hostname    = each.key
  zone        = each.value.zone
  platform_id = "standard-v2"

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2404.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    # Переключаем подсети в зависимости от настроек зоны ноды
    subnet_id = (
      each.value.zone == "ru-central1-a" ? yandex_vpc_subnet.subnet_a.id :
      each.value.zone == "ru-central1-d" ? yandex_vpc_subnet.subnet_d.id :
      yandex_vpc_subnet.subnet_e.id
    )
    nat       = each.key == "master-1" ? true : false
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }
}

# Генерация hosts.ini под новые зоны
resource "local_file" "kubespray_inventory" {
  content = <<EOT
[all]
master-1 ansible_host=${yandex_compute_instance.k8s_node["master-1"].network_interface.0.nat_ip_address} ip=${yandex_compute_instance.k8s_node["master-1"].network_interface.0.ip_address} ansible_user=ubuntu
worker-1 ansible_host=${yandex_compute_instance.k8s_node["worker-1"].network_interface.0.ip_address} ip=${yandex_compute_instance.k8s_node["worker-1"].network_interface.0.ip_address} ansible_user=ubuntu ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@${yandex_compute_instance.k8s_node["master-1"].network_interface.0.nat_ip_address}"'
worker-2 ansible_host=${yandex_compute_instance.k8s_node["worker-2"].network_interface.0.ip_address} ip=${yandex_compute_instance.k8s_node["worker-2"].network_interface.0.ip_address} ansible_user=ubuntu ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@${yandex_compute_instance.k8s_node["master-1"].network_interface.0.nat_ip_address}"'
worker-3 ansible_host=${yandex_compute_instance.k8s_node["worker-3"].network_interface.0.ip_address} ip=${yandex_compute_instance.k8s_node["worker-3"].network_interface.0.ip_address} ansible_user=ubuntu ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q ubuntu@${yandex_compute_instance.k8s_node["master-1"].network_interface.0.nat_ip_address}"'

[kube_control_plane]
master-1

[etcd]
master-1

[kube_node]
worker-1
worker-2
worker-3

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
EOT

  filename = "${path.module}/kubespray/inventory/mycluster/hosts.ini"
}
