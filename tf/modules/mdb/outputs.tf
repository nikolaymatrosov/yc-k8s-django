output "postgres_password_secret_id" {
  value = yandex_lockbox_secret.django-password.id
}

output "postgres_user" {
  value = yandex_mdb_postgresql_user.django-user.name
}

output "postgres_database" {
  value = yandex_mdb_postgresql_database.django-db.name
}

output "postgres_host" {
  value = "c-${yandex_mdb_postgresql_cluster.django-cluster.id}.rw.mdb.yandexcloud.net"
}
