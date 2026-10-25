resource "yandex_vpc_network" "k8s_network" {
  name = "k8s-network"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "k8s-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "k8s-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.131.0.0/24"] # Задаем уникальную подсеть для D
}

resource "yandex_vpc_subnet" "subnet_e" {
  name           = "k8s-subnet-e"
  zone           = "ru-central1-e"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.132.0.0/24"] # Задаем уникальную подсеть для E
}
