resource "google_project_service" "services" {
  for_each = toset(var.project_services)

  service            = each.value
  disable_on_destroy = false
}
