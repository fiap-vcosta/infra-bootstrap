data "google_compute_default_service_account" "default" {}

resource "google_project_iam_member" "ci" {
  for_each = toset(var.ci_project_roles)

  project = var.project_id
  role    = each.value
  member  = google_service_account.ci.member
}

resource "google_service_account_iam_member" "ci_node_service_account_user" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.ci.member
}
