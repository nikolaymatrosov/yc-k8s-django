# Ensure it exists.
data "yandex_vpc_network" "default" {
  network_id = var.network_id
}

data "yandex_vpc_subnet" "default_a" {
  subnet_id = var.subnet_id_a
}
