resource "google_service_account" "api_runtime" {
  account_id   = var.runtime_service_account_id
  display_name = "Tech Challenge API runtime"
}

resource "google_project_iam_member" "api_runtime_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = google_service_account.api_runtime.member
}

resource "google_service_account_iam_member" "ci_api_runtime_iam_policy" {
  service_account_id = google_service_account.api_runtime.name
  role               = google_project_iam_custom_role.service_account_iam_policy_writer.id
  member             = google_service_account.ci.member
}
