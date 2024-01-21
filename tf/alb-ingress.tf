resource "yandex_iam_service_account" "k8s_cluster_alb" {
  folder_id   = var.folder_id
  description = "Service account for k8s cluster ALB Ingress Controller"
  name        = "k8s-cluster-alb-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_alb_roles" {
  folder_id = var.folder_id

  //alb.editor — для создания необходимых ресурсов.
  //vpc.publicAdmin — для управления внешней связностью.
  //certificate-manager.certificates.downloader — для работы с сертификатами, зарегистрированными в сервисе Yandex Certificate Manager.
  //compute.viewer — для использования узлов кластера Managed Service for Kubernetes в целевых группах балансировщика.
  for_each = toset([
    "alb.editor",
    "vpc.publicAdmin",
    "certificate-manager.certificates.downloader",
    "compute.viewer",
  ])
  role       = each.value
  member     = "serviceAccount:${yandex_iam_service_account.k8s_cluster_alb.id}"
  depends_on = [
    yandex_iam_service_account.k8s_cluster_alb,
  ]
  sleep_after = 5
}

resource "yandex_iam_service_account_key" "k8s_cluster_alb" {
  service_account_id = yandex_iam_service_account.k8s_cluster_alb.id
  depends_on         = [
    yandex_iam_service_account.k8s_cluster_alb,
  ]
}

resource "kubernetes_namespace" "alb_ingress" {
  metadata {
    name = "alb-ingress"
  }
}

resource "kubernetes_secret" "yc_alb_ingress_controller_sa_key" {
  metadata {
    name      = "yc-alb-ingress-controller-sa-key"
    namespace = "alb-ingress"
  }
  data = {
    "sa-key.json" = jsonencode(
      {
        "id" : yandex_iam_service_account_key.k8s_cluster_alb.id,
        "service_account_id" : yandex_iam_service_account_key.k8s_cluster_alb.service_account_id,
        "created_at" : yandex_iam_service_account_key.k8s_cluster_alb.created_at,
        "key_algorithm" : yandex_iam_service_account_key.k8s_cluster_alb.key_algorithm,
        "public_key" : yandex_iam_service_account_key.k8s_cluster_alb.public_key,
        "private_key" : yandex_iam_service_account_key.k8s_cluster_alb.private_key
      }
    )
  }

  type       = "kubernetes.io/Opaque"
  depends_on = [
    kubernetes_namespace.alb_ingress
  ]
}

resource "helm_release" "alb_ingress" {
  name             = "alb-ingress"
  namespace        = "alb-ingress"
  repository       = "oci://cr.yandex/yc-marketplace/yandex-cloud/yc-alb-ingress"
  chart            = "yc-alb-ingress-controller-chart"
  version          = "v0.1.24"
  create_namespace = true

  values = [
    <<-EOF
    folderId: ${var.folder_id}
    clusterId: ${module.k8s.cluster_id}
    daemonsetTolerations:
      - operator: Exists
    auth:
      json: ${jsonencode(
      {
        "id" : yandex_iam_service_account_key.k8s_cluster_alb.id,
        "service_account_id" : yandex_iam_service_account_key.k8s_cluster_alb.service_account_id,
        "created_at" : yandex_iam_service_account_key.k8s_cluster_alb.created_at,
        "key_algorithm" : yandex_iam_service_account_key.k8s_cluster_alb.key_algorithm,
        "public_key" : yandex_iam_service_account_key.k8s_cluster_alb.public_key,
        "private_key" : yandex_iam_service_account_key.k8s_cluster_alb.private_key
      }
    )}
  EOF
  ]

  depends_on = [
    module.k8s,
    yandex_resourcemanager_folder_iam_member.k8s_cluster_alb_roles,
    yandex_iam_service_account_key.k8s_cluster_alb,
    kubernetes_namespace.alb_ingress,
    kubernetes_secret.yc_alb_ingress_controller_sa_key
  ]
}

resource "yandex_vpc_security_group" "alb" {
  name        = "k8s-alb"
  description = "alb security group"
  network_id  = module.k8s.network_id
  folder_id   = var.folder_id

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol          = "TCP"
    description       = "Rule allows availability checks from load balancer's address range. It is required for a db cluster"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "Rule allows master and slave communication inside a security group."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  egress {
    protocol       = "TCP"
    description    = "Enable traffic from ALB to K8s services"
    #    predefined_target = "self_security_group"
    v4_cidr_blocks = flatten([for cidr in module.k8s.subnet_cidr : cidr])
    from_port      = 30000
    to_port        = 65535
  }

  egress {
    protocol       = "TCP"
    description    = "Enable probes from ALB to K8s"
    v4_cidr_blocks = flatten([for cidr in module.k8s.subnet_cidr : cidr])
    port           = 10501
  }
}
