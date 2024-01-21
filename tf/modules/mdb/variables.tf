variable "cloud_id" {
  description = "Cloud ID"
  type        = string
}
variable "folder_id" {
  description = "Folder ID"
  type        = string
}
variable "zone" {
  description = "Zone"
  type        = string
  default     = "ru-central1-a"
}
variable "network_id" {
  description = "Network ID"
  type        = string
}
variable "subnet_id_a" {
  description = "Subnet ID in zone A"
  type        = string
}
