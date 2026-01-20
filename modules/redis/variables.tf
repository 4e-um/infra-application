variable "name" {
  description = "Redis instance name suffix"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone for the Redis VM"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self_link for the Redis VM"
  type        = string
}

variable "redis_password" {
  description = "Redis authentication password"
  type        = string
  sensitive   = true
}

variable "service_account_email" {
  description = "Service account email for the Redis VM"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the Redis VM"
  type        = string
  default     = "e2-micro"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "labels" {
  description = "Labels to apply to the Redis VM"
  type        = map(string)
  default     = {}
}
