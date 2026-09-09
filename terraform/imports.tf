import {
  to = google_project_service.services["cloudresourcemanager.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/cloudresourcemanager.googleapis.com"
}

import {
  to = google_project_service.services["compute.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/compute.googleapis.com"
}

import {
  to = google_project_service.services["iam.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/iam.googleapis.com"
}

import {
  to = google_project_service.services["iamcredentials.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/iamcredentials.googleapis.com"
}

import {
  to = google_project_service.services["secretmanager.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/secretmanager.googleapis.com"
}

import {
  to = google_project_service.services["servicenetworking.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/servicenetworking.googleapis.com"
}

import {
  to = google_project_service.services["sqladmin.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/sqladmin.googleapis.com"
}

import {
  to = google_project_service.services["storage.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/storage.googleapis.com"
}

import {
  to = google_project_service.services["sts.googleapis.com"]
  id = "vcosta-fiap-tech-challenge/sts.googleapis.com"
}

import {
  to = google_storage_bucket.state
  id = "vcosta-fiap-tech-challenge/vcosta-fiap-tech-challenge-tfstate"
}

import {
  to = google_storage_bucket_iam_member.ci_state_object_admin
  id = "b/vcosta-fiap-tech-challenge-tfstate roles/storage.objectAdmin serviceAccount:github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com"
}

import {
  to = google_iam_workload_identity_pool.github
  id = "projects/vcosta-fiap-tech-challenge/locations/global/workloadIdentityPools/github"
}

import {
  to = google_iam_workload_identity_pool_provider.github
  id = "projects/vcosta-fiap-tech-challenge/locations/global/workloadIdentityPools/github/providers/github"
}

import {
  to = google_service_account.ci
  id = "projects/vcosta-fiap-tech-challenge/serviceAccounts/github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com"
}

import {
  to = google_service_account_iam_member.ci_workload_identity
  id = "projects/vcosta-fiap-tech-challenge/serviceAccounts/github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com roles/iam.workloadIdentityUser principalSet://iam.googleapis.com/projects/279569531443/locations/global/workloadIdentityPools/github/attribute.repository_owner/fiap-vcosta"
}

import {
  to = google_project_iam_member.ci["roles/cloudsql.admin"]
  id = "vcosta-fiap-tech-challenge roles/cloudsql.admin serviceAccount:github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com"
}

import {
  to = google_project_iam_member.ci["roles/compute.networkAdmin"]
  id = "vcosta-fiap-tech-challenge roles/compute.networkAdmin serviceAccount:github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com"
}

import {
  to = google_project_iam_member.ci["roles/secretmanager.admin"]
  id = "vcosta-fiap-tech-challenge roles/secretmanager.admin serviceAccount:github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com"
}

import {
  to = google_project_iam_member.ci["roles/viewer"]
  id = "vcosta-fiap-tech-challenge roles/viewer serviceAccount:github-actions@vcosta-fiap-tech-challenge.iam.gserviceaccount.com"
}
