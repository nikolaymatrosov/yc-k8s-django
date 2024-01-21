output "repo_url" {
  value = module.k8s.repo_url
}

output "external_secrets_sa" {
  value = yandex_iam_service_account.external_secrets_sa.name
}

output "postgres_password_secret_id" {
  value = module.mdb.postgres_password_secret_id
}

output "postgres_host" {
  value = module.mdb.postgres_host
}

output "subnet_ids" {
  value = flatten([for subnet in module.k8s.subnet_id: subnet])
}

output "security_group_id" {
  value = yandex_vpc_security_group.alb.id
}

output "certificate_id" {
  value = yandex_cm_certificate.django-cert.id
}

output "alb_ip_address" {
  value = yandex_vpc_address.alb-external-ip.external_ipv4_address[0].address
}