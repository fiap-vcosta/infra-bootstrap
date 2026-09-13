variable "project_id" {
  type        = string
  description = "GCP project ID da demo."
  default     = "vcosta-fiap-tech-challenge"
}

variable "region" {
  type        = string
  description = "Região primária."
  default     = "us-central1"
}

variable "project_services" {
  type        = list(string)
  description = "APIs mantidas habilitadas para os stacks do projeto."
  default = [
    "apigateway.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicecontrol.googleapis.com",
    "servicemanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ]
}

variable "state_bucket_name" {
  type        = string
  description = "Bucket GCS do backend de state dos stacks."
  default     = "vcosta-fiap-tech-challenge-tfstate"
}

variable "github_org" {
  type        = string
  description = "Org do GitHub autorizada no provider OIDC."
  default     = "fiap-vcosta"
}

variable "workload_identity_pool_id" {
  type        = string
  description = "ID do Workload Identity Pool do GitHub."
  default     = "github"
}

variable "ci_service_account_id" {
  type        = string
  description = "Account ID da service account usada pelos workflows."
  default     = "github-actions"
}

variable "ci_repositories" {
  type        = list(string)
  description = "Repositórios da org cujos workflows podem assumir a service account de CI."
  default = [
    "api",
    "auth",
    "infra-db",
    "infra-k8s",
  ]
}

variable "ci_project_roles" {
  type        = list(string)
  description = "Roles de projeto da service account de CI (least-privilege, sem editor)."
  default = [
    "roles/apigateway.admin",
    "roles/artifactregistry.writer",
    "roles/cloudfunctions.developer",
    "roles/cloudsql.admin",
    "roles/compute.networkAdmin",
    "roles/container.admin",
    "roles/dns.admin",
    "roles/run.admin",
    "roles/secretmanager.admin",
    "roles/servicemanagement.admin",
    "roles/viewer",
  ]
}

variable "network_name" {
  type        = string
  description = "Nome da VPC dedicada."
  default     = "tech-challenge-vpc"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR primário da subnet regional (nós do cluster)."
  default     = "10.10.0.0/24"
}

variable "pods_range_name" {
  type        = string
  description = "Nome do range secundário de pods do cluster."
  default     = "pods"
}

variable "pods_cidr" {
  type        = string
  description = "CIDR do range secundário de pods."
  default     = "10.60.0.0/16"
}

variable "services_range_name" {
  type        = string
  description = "Nome do range secundário de services do cluster."
  default     = "services"
}

variable "services_cidr" {
  type        = string
  description = "CIDR do range secundário de services."
  default     = "10.61.0.0/20"
}

variable "psa_range_address" {
  type        = string
  description = "Início do range reservado ao Private Service Access."
  default     = "10.100.0.0"
}

variable "psa_range_prefix_length" {
  type        = number
  description = "Prefixo do range reservado ao Private Service Access."
  default     = 16
}

variable "registry_repository_id" {
  type        = string
  description = "Repositório Docker do Artifact Registry."
  default     = "tech-challenge"
}

variable "registry_keep_versions" {
  type        = number
  description = "Quantidade de tags recentes preservadas pela cleanup policy."
  default     = 5
}

variable "runtime_service_account_id" {
  type        = string
  description = "Account ID da service account de runtime da API."
  default     = "tech-challenge-api"
}

variable "dns_managed_zone_name" {
  type        = string
  description = "Nome da managed zone pública no Cloud DNS."
  default     = "tech-challenge"
}

variable "dns_name" {
  type        = string
  description = "DNS name da zona (FQDN com ponto final)."
  default     = "vcosta-fiap.online."
}

