resource "yandex_iam_service_account" "external_secrets_sa" {
  folder_id   = var.folder_id
  description = "Service account External Secrets"
  name        = "external-secrets-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "external_secrets_sa_roles" {
  folder_id = var.folder_id
  for_each  = toset([
    "kms.keys.encrypterDecrypter", // This role is needed to decrypt secrets in lockbox
    "lockbox.viewer", // This role is needed to view secrets in lockbox
    "lockbox.payloadViewer", // This role is needed to view secrets payloads in lockbox
  ])
  role       = each.value
  member     = "serviceAccount:${yandex_iam_service_account.external_secrets_sa.id}"
  depends_on = [
    yandex_iam_service_account.external_secrets_sa,
  ]
  sleep_after = 5
}

resource "yandex_iam_service_account_key" "external_secrets_sa_key" {
  service_account_id = yandex_iam_service_account.external_secrets_sa.id
  depends_on         = [
    yandex_iam_service_account.external_secrets_sa,
  ]
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}


resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  repository       = "oci://cr.yandex/yc-marketplace/yandex-cloud/external-secrets/chart"
  chart            = "external-secrets"
  version          = "0.5.5"
  create_namespace = true

  values = [
    <<-EOF
    auth.json: ${jsonencode(
      {
        "id" : yandex_iam_service_account_key.external_secrets_sa_key.id,
        "service_account_id" : yandex_iam_service_account_key.external_secrets_sa_key.service_account_id,
        "created_at" : yandex_iam_service_account_key.external_secrets_sa_key.created_at,
        "key_algorithm" : yandex_iam_service_account_key.external_secrets_sa_key.key_algorithm,
        "public_key" : yandex_iam_service_account_key.external_secrets_sa_key.public_key,
        "private_key" : yandex_iam_service_account_key.external_secrets_sa_key.private_key
      }
    )}
  EOF
  ]

  depends_on = [
    yandex_resourcemanager_folder_iam_member.external_secrets_sa_roles,
    yandex_iam_service_account_key.external_secrets_sa_key,
    kubernetes_namespace.external_secrets,
    module.k8s.node_group_id,
  ]
}
