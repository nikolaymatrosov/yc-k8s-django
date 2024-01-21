resource "yandex_cm_certificate" "django-cert" {
  name    = "django-cert"
  domains = ["matrosov.xyz"]

  managed {
    challenge_type  = "DNS_CNAME"
    challenge_count = 1
  }
}

resource "yandex_dns_zone" "django-zone" {
  name = "django-zone"
  zone   = "matrosov.xyz."
  public = true
}

resource "yandex_dns_recordset" "django-cert" {
  count   = yandex_cm_certificate.django-cert.managed[0].challenge_count
  zone_id = yandex_dns_zone.django-zone.id
  name    = yandex_cm_certificate.django-cert.challenges[count.index].dns_name
  type    = yandex_cm_certificate.django-cert.challenges[count.index].dns_type
  data    = [yandex_cm_certificate.django-cert.challenges[count.index].dns_value]
  ttl     = 60
}

resource "yandex_vpc_address" "alb-external-ip" {
  name = "alb-external-ip"

  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}


resource "yandex_dns_recordset" "matrosov-xyz" {
  zone_id = yandex_dns_zone.django-zone.id
  name    = "matrosov.xyz."
  type    = "A"
  ttl     = 60
  data    = [yandex_vpc_address.alb-external-ip.external_ipv4_address[0].address]
}