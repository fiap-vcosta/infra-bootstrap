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

output "runtime_service_account_emails" {
  description = "E-mails das service accounts de runtime, uma por serviço. A chave é o account id."
  value       = { for id, sa in google_service_account.runtime : id => sa.email }
}

output "dns_managed_zone_name" {
  description = "Nome da managed zone pública consumida pelo infra-k8s."
  value       = google_dns_managed_zone.public.name
}

output "dns_name" {
  description = "DNS name da zona (FQDN com ponto final)."
  value       = google_dns_managed_zone.public.dns_name
}

output "dns_name_servers" {
  description = "Nameservers Google a configurar no registrador (Hostinger)."
  value       = google_dns_managed_zone.public.name_servers
}
