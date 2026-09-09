data "google_compute_default_service_account" "default" {}

resource "google_project_iam_member" "ci" {
  for_each = toset(var.ci_project_roles)

  project = var.project_id
  role    = each.value
  member  = google_service_account.ci.member
}

resource "google_project_iam_custom_role" "service_account_iam_policy_writer" {
  role_id     = "serviceAccountIamPolicyWriter"
  title       = "Service Account IAM Policy Writer"
  description = "Permite apenas ler e gravar a policy IAM da service account em que a role é concedida."
  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
  ]
}

resource "google_service_account_iam_member" "ci_node_service_account_user" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.ci.member
}
