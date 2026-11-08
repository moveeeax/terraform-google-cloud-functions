resource "google_cloudfunctions2_function" "this" {
  project  = var.project_id
  name     = var.name
  location = var.location
  labels   = var.labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = var.source_bucket
        object = var.source_object
      }
    }
  }

  service_config {
    max_instance_count    = var.max_instance_count
    available_memory      = var.available_memory
    environment_variables = var.environment_variables

    # Controls which networks can reach the function endpoint. Defaults to
    # ALLOW_INTERNAL_ONLY so a function is never published to the public
    # internet unless the caller explicitly opts in.
    ingress_settings = var.ingress_settings

    # When left null the platform falls back to the App Engine / Compute
    # default service account, which carries project-wide Editor. Callers
    # should supply a dedicated least-privilege service account instead.
    service_account_email = var.service_account_email

    # Serverless VPC Access connector for outbound calls to private IPs, e.g.
    # Cloud SQL private IP or internal load balancers. Both stay null by
    # default, which keeps all egress on the public internet path.
    vpc_connector                 = var.vpc_connector
    vpc_connector_egress_settings = var.vpc_connector_egress_settings

    # Secret Manager references are injected by the platform at runtime, so
    # the values never appear in Terraform state or in the function config.
    dynamic "secret_environment_variables" {
      for_each = { for s in var.secret_environment_variables : s.key => s }

      content {
        key        = secret_environment_variables.value.key
        secret     = secret_environment_variables.value.secret
        version    = secret_environment_variables.value.version
        project_id = coalesce(secret_environment_variables.value.project_id, var.project_id)
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.vpc_connector_egress_settings == null || var.vpc_connector != null
      error_message = "vpc_connector_egress_settings only takes effect with a vpc_connector. Set vpc_connector as well, or leave vpc_connector_egress_settings null."
    }
  }
}
