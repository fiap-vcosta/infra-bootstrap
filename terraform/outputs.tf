output "network_id" {
  description = "Self-link/id da VPC compartilhada pelos stacks."
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "Nome da VPC."
  value       = google_compute_network.main.name
}

output "subnet_id" {
  description = "Self-link/id da subnet regional."
  value       = google_compute_subnetwork.main.id
}

output "subnet_name" {
  description = "Nome da subnet regional."
  value       = google_compute_subnetwork.main.name
}

output "pods_range_name" {
  description = "Range secundário de pods do cluster."
  value       = var.pods_range_name
}

output "services_range_name" {
  description = "Range secundário de services do cluster."
  value       = var.services_range_name
}

output "registry_url" {
  description = "Host/path do repositório Docker no Artifact Registry."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.api.repository_id}"
}

output "api_runtime_service_account_email" {
  description = "Service account de runtime da API (destino do Workload Identity)."
  value       = google_service_account.api_runtime.email
}

output "ci_service_account_email" {
  description = "Service account usada pelos workflows."
  value       = google_service_account.ci.email
}
