terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "source" {
  project                     = var.project_id
  name                        = "${var.project_id}-fn-source"
  location                    = var.region
  uniform_bucket_level_access = true
}

# Dedicated least-privilege identity for the function. Without this the
# function would run as the App Engine default service account, which holds
# project-wide Editor.
resource "google_service_account" "function" {
  project      = var.project_id
  account_id   = "example-function-runtime"
  display_name = "Runtime identity for the example Cloud Function"
}

module "function" {
  source = "../.."

  project_id    = var.project_id
  name          = "example-function"
  location      = var.region
  runtime       = "nodejs22"
  entry_point   = "helloWorld"
  source_bucket = google_storage_bucket.source.name
  source_object = "function-source.zip"

  service_account_email = google_service_account.function.email

  # Internal-only is the module default; spelled out here to make the choice
  # visible. Use "ALLOW_ALL" for a function meant to serve public traffic.
  ingress_settings = "ALLOW_INTERNAL_ONLY"
}

variable "project_id" {
  description = "Project ID to deploy the example function into."
  type        = string
}

variable "region" {
  description = "Region for the google provider and function."
  type        = string
  default     = "us-central1"
}

output "function_uri" {
  value = module.function.uri
}
