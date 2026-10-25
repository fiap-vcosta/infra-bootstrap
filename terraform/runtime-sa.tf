resource "google_service_account" "runtime" {
  for_each = var.runtime_service_accounts

  account_id   = each.key
  display_name = "Tech Challenge ${each.key} runtime"
}

resource "google_project_iam_member" "runtime_cloudsql_client" {
  for_each = {
    for id, sa in var.runtime_service_accounts : id => sa
    if sa.cloudsql_client
  }

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = google_service_account.runtime[each.key].member
}

resource "google_project_iam_member" "runtime_firestore_user" {
  for_each = {
    for id, sa in var.runtime_service_accounts : id => sa
    if sa.firestore_user
  }

  project = var.project_id
  role    = "roles/datastore.user"
  member  = google_service_account.runtime[each.key].member
}

resource "google_service_account_iam_member" "ci_runtime_iam_policy" {
  for_each = var.runtime_service_accounts

  service_account_id = google_service_account.runtime[each.key].name
  role               = google_project_iam_custom_role.service_account_iam_policy_writer.id
  member             = google_service_account.ci.member
}
