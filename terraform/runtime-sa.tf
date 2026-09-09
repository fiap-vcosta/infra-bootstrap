resource "google_service_account" "api_runtime" {
  account_id   = var.runtime_service_account_id
  display_name = "Tech Challenge API runtime"
}

resource "google_project_iam_member" "api_runtime_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = google_service_account.api_runtime.member
}

resource "google_service_account_iam_member" "api_runtime_workload_identity" {
  service_account_id = google_service_account.api_runtime.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"
}
