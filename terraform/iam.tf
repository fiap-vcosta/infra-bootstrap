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

resource "google_project_iam_custom_role" "gateway_entry_lb" {
  role_id     = "gatewayEntryLb"
  title       = "Gateway Entry LB"
  description = "NEG serverless e certificados SSL do HTTPS LB da entrada (apex → API Gateway)."
  permissions = [
    "compute.regionNetworkEndpointGroups.create",
    "compute.regionNetworkEndpointGroups.delete",
    "compute.regionNetworkEndpointGroups.get",
    "compute.regionNetworkEndpointGroups.list",
    "compute.regionNetworkEndpointGroups.use",
    "compute.sslCertificates.create",
    "compute.sslCertificates.delete",
    "compute.sslCertificates.get",
    "compute.sslCertificates.list",
  ]
}

resource "google_project_iam_member" "ci_gateway_entry_lb" {
  project = var.project_id
  role    = google_project_iam_custom_role.gateway_entry_lb.id
  member  = google_service_account.ci.member
}

resource "google_service_account_iam_member" "ci_node_service_account_user" {
  service_account_id = data.google_compute_default_service_account.default.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.ci.member
}
