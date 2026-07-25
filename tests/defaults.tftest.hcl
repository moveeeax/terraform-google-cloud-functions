# NOTE: `terraform test` with `mock_provider` requires Terraform >= 1.7.
# The module itself still supports >= 1.5 (see versions.tf) — this extra
# requirement applies to running the test suite only, not to consumers.

mock_provider "google" {}

variables {
  project_id    = "example-project"
  name          = "test-function"
  location      = "us-central1"
  entry_point   = "handler"
  source_bucket = "example-source-bucket"
  source_object = "source.zip"
}

run "defaults_are_safe" {
  assert {
    condition     = google_cloudfunctions2_function.this.service_config[0].ingress_settings == "ALLOW_INTERNAL_ONLY"
    error_message = "Functions must not be reachable from the public internet by default."
  }

  assert {
    condition     = length(google_cloudfunctions2_function.this.service_config[0].secret_environment_variables) == 0
    error_message = "No secret environment variables should be configured by default."
  }

  assert {
    condition     = google_cloudfunctions2_function.this.service_config[0].max_instance_count == 100
    error_message = "max_instance_count must stay bounded by default so a traffic spike cannot scale without limit."
  }

  assert {
    condition     = google_cloudfunctions2_function.this.build_config[0].runtime == "nodejs22"
    error_message = "The default runtime must be a currently supported one."
  }
}

run "runtime_service_account_is_wired_through" {
  variables {
    service_account_email = "fn-runtime@example-project.iam.gserviceaccount.com"
  }

  assert {
    condition     = google_cloudfunctions2_function.this.service_config[0].service_account_email == "fn-runtime@example-project.iam.gserviceaccount.com"
    error_message = "service_account_email must be passed to the function's service config."
  }
}

run "secrets_are_mounted_from_secret_manager" {
  variables {
    secret_environment_variables = [
      {
        key    = "API_TOKEN"
        secret = "api-token"
      },
      {
        key        = "DB_PASSWORD"
        secret     = "db-password"
        version    = "3"
        project_id = "shared-secrets-project"
      },
    ]
  }

  assert {
    condition     = length(google_cloudfunctions2_function.this.service_config[0].secret_environment_variables) == 2
    error_message = "Both secret environment variables should be configured."
  }

  assert {
    condition = anytrue([
      for s in google_cloudfunctions2_function.this.service_config[0].secret_environment_variables :
      s.key == "API_TOKEN" && s.secret == "api-token" && s.version == "latest" && s.project_id == "example-project"
    ])
    error_message = "version must default to latest and project_id to the function's project."
  }

  assert {
    condition = anytrue([
      for s in google_cloudfunctions2_function.this.service_config[0].secret_environment_variables :
      s.key == "DB_PASSWORD" && s.version == "3" && s.project_id == "shared-secrets-project"
    ])
    error_message = "An explicit secret version and project must be honoured."
  }
}

run "public_ingress_is_opt_in" {
  variables {
    ingress_settings = "ALLOW_ALL"
  }

  assert {
    condition     = google_cloudfunctions2_function.this.service_config[0].ingress_settings == "ALLOW_ALL"
    error_message = "Callers must be able to opt into public ingress explicitly."
  }
}

run "rejects_invalid_ingress_settings" {
  command = plan

  variables {
    ingress_settings = "PUBLIC"
  }

  expect_failures = [var.ingress_settings]
}

run "rejects_zero_max_instance_count" {
  command = plan

  variables {
    max_instance_count = 0
  }

  expect_failures = [var.max_instance_count]
}

run "rejects_malformed_service_account_email" {
  command = plan

  variables {
    service_account_email = "not-an-email"
  }

  expect_failures = [var.service_account_email]
}

run "rejects_duplicate_secret_keys" {
  command = plan

  variables {
    secret_environment_variables = [
      { key = "API_TOKEN", secret = "api-token" },
      { key = "API_TOKEN", secret = "other-token" },
    ]
  }

  expect_failures = [var.secret_environment_variables]
}
