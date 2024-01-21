module "k8s" {
  source = "modules/k8s"

  cloud_id   = var.cloud_id
  folder_id  = var.folder_id
}
