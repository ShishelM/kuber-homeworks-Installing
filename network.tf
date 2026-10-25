resource "yandex_vpc_network" "k8s_network" {
  name = "k8s-network"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "k8s-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.128.0.0/24"]
  route_table_id = yandex_vpc_route_table.k8s_rt.id 
}

resource "yandex_vpc_subnet" "subnet_d" {
  name           = "k8s-subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.131.0.0/24"]
  route_table_id = yandex_vpc_route_table.k8s_rt.id 
}

resource "yandex_vpc_subnet" "subnet_e" {
  name           = "k8s-subnet-e"
  zone           = "ru-central1-e"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.132.0.0/24"]
  route_table_id = yandex_vpc_route_table.k8s_rt.id 
}

# Создаем группу безопасности для доступа к кластеру
resource "yandex_vpc_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  network_id  = yandex_vpc_network.k8s_network.id

  # Разрешаем входящий SSH снаружи для настройки
  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Разрешаем весь внутренний трафик между нодами в VPC сети
  ingress {
    protocol       = "ANY"
    description    = "Allow internal traffic"
    v4_cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
    from_port      = 0
    to_port        = 65535
  }

  # Разрешаем нодам ходить в интернет за пакетами/интернетом
  egress {
    protocol       = "ANY"
    description    = "Allow outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# 1. Создаем шлюз NAT для выхода приватных нод в интернет
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "k8s-nat-gateway"
  shared_egress_gateway {}
}

# 2. Создаем таблицу маршрутизации, которая пустит трафик 0.0.0.0/0 через этот шлюз
resource "yandex_vpc_route_table" "k8s_rt" {
  name       = "k8s-route-table"
  network_id = yandex_vpc_network.k8s_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
