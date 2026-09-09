output "network_id" {
  description = "Self-link/id da VPC compartilhada pelos stacks."
  value       = google_compute_network.main.id
}

output "subnet_id" {
  description = "Self-link/id da subnet regional do cluster."
  value       = google_compute_subnetwork.main.id
}

output "pods_range_name" {
  description = "Range secundário de pods do cluster."
  value       = var.pods_range_name
}

output "services_range_name" {
  description = "Range secundário de services do cluster."
  value       = var.services_range_name
}

output "api_runtime_service_account_email" {
  description = "Service account de runtime da API, anotada na KSA pelo infra-k8s."
  value       = google_service_account.api_runtime.email
}
