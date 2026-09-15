resource "google_artifact_registry_repository" "api" {
  location      = var.region
  repository_id = var.registry_repository_id
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"

    condition {
      tag_state  = "ANY"
      older_than = var.registry_delete_older_than
    }
  }

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"

    most_recent_versions {
      keep_count = var.registry_keep_versions
    }
  }

  depends_on = [google_project_service.services]
}
