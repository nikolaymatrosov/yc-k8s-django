resource "yandex_container_registry" "django-registry" {
  name      = "django-registry"
  folder_id = var.folder_id
}

resource "yandex_container_repository" "django-repo" {
  name = "${yandex_container_registry.django-registry.id}/django-app"
}
