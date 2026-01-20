output "instance_id" {
  description = "Redis VM instance ID"
  value       = google_compute_instance.redis.id
}

output "instance_name" {
  description = "Redis VM instance name"
  value       = google_compute_instance.redis.name
}

output "private_ip" {
  description = "Redis VM private IP address"
  value       = google_compute_instance.redis.network_interface[0].network_ip
}

output "external_ip" {
  description = "Redis VM external IP address"
  value       = google_compute_instance.redis.network_interface[0].access_config[0].nat_ip
}

output "self_link" {
  description = "Redis VM self link"
  value       = google_compute_instance.redis.self_link
}

output "zone" {
  description = "Redis VM zone"
  value       = google_compute_instance.redis.zone
}
