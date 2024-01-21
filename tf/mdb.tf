module "mdb" {
  source = "./modules/mdb"

  cloud_id    = var.cloud_id
  folder_id   = var.folder_id
  network_id  = module.k8s.network_id
  subnet_id_a = module.k8s.subnet_id["a"]
}
