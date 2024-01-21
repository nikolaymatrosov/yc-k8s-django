resource "yandex_mdb_postgresql_cluster" "django-cluster" {
  name        = "django-db"
  environment = "PRODUCTION"
  network_id  = data.yandex_vpc_network.default.id

  config {
    version = 15
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 16
    }
    postgresql_config = {
      max_connections                = 395
      enable_parallel_hash           = true
      autovacuum_vacuum_scale_factor = 0.34
      default_transaction_isolation  = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries       = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 12
  }

  host {
    zone      = var.zone
    subnet_id = data.yandex_vpc_subnet.default_a.id
  }
}

resource "yandex_mdb_postgresql_database" "django-db" {
  cluster_id = yandex_mdb_postgresql_cluster.django-cluster.id
  name       = "django"
  owner      = yandex_mdb_postgresql_user.django-user.name
  lc_collate = "en_US.UTF-8"
  lc_type    = "en_US.UTF-8"

  extension {
    name = "uuid-ossp"
  }

}

resource "random_password" "django-password" {
  length           = 24
  special          = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "-_()[]{}!%^"
}


resource "yandex_mdb_postgresql_user" "django-user" {
  cluster_id = yandex_mdb_postgresql_cluster.django-cluster.id
  name       = "django"
  password   = random_password.django-password.result
}

resource "yandex_lockbox_secret" "django-password" {
  name = "MDB password for django database"
}

resource "yandex_lockbox_secret_version" "django-password" {
  secret_id = yandex_lockbox_secret.django-password.id
  entries {
    key        = "password"
    text_value = random_password.django-password.result
  }
}