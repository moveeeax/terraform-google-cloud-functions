# terraform-google-cloud-functions

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
2nd generation Cloud Function (`google_cloudfunctions2_function`). It builds the
function from a source archive in Cloud Storage and runs it on Cloud Run.

## Usage

```hcl
resource "google_storage_bucket" "source" {
  project                     = var.project_id
  name                        = "${var.project_id}-processor-source"
  location                    = "US"
  uniform_bucket_level_access = true
}

resource "google_service_account" "function" {
  project    = var.project_id
  account_id = "processor-runtime"
}

module "function" {
  source = "github.com/moveeeax/terraform-google-cloud-functions?ref=v1.0.0"

  project_id    = var.project_id
  name          = "processor"
  location      = "us-central1"
  runtime       = "python312"
  entry_point   = "handle"
  source_bucket = google_storage_bucket.source.name
  source_object = "source.zip"

  service_account_email = google_service_account.function.email

  secret_environment_variables = [
    {
      key    = "API_TOKEN"
      secret = "processor-api-token"
    },
  ]
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Security defaults

| Concern | What this module does |
|---------|-----------------------|
| Public invocation | The module grants **no** IAM invoker binding. Nothing is granted to `allUsers`, so every call must be authenticated. |
| Network exposure | `ingress_settings` defaults to `ALLOW_INTERNAL_ONLY`, not the platform's `ALLOW_ALL`. Set it to `ALLOW_ALL` to serve public traffic. |
| Runtime identity | `service_account_email` is passed straight through. Leaving it `null` falls back to the App Engine / Compute default service account, which holds project-wide Editor — pass a dedicated service account. |
| Secrets | Use `secret_environment_variables` for credentials. Values are resolved from Secret Manager by the platform at runtime and never enter Terraform state. `environment_variables` is plaintext and should hold configuration only. |
| Cost | `max_instance_count` defaults to `100` and must be at least `1`, so a traffic spike cannot scale the function without bound. |

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

Running the test suite in [`tests/`](tests) additionally needs Terraform >= 1.7
for `mock_provider`; consumers of the module are unaffected.

## Inputs

| Name                           | Description                                                                       | Type                | Default                   | Required |
|--------------------------------|-----------------------------------------------------------------------------------|---------------------|---------------------------|:--------:|
| `project_id`                   | ID of the project in which to create the function.                                | `string`            | n/a                       |   yes    |
| `name`                         | Name of the Cloud Function.                                                       | `string`            | n/a                       |   yes    |
| `location`                     | Region in which to deploy the function.                                           | `string`            | n/a                       |   yes    |
| `runtime`                      | Runtime to run the function.                                                      | `string`            | `"nodejs22"`              |    no    |
| `entry_point`                  | Name of the function executed in the source.                                      | `string`            | n/a                       |   yes    |
| `source_bucket`                | Bucket holding the source archive.                                                | `string`            | n/a                       |   yes    |
| `source_object`                | Object path of the source archive.                                                | `string`            | n/a                       |   yes    |
| `available_memory`             | Memory available to the function.                                                 | `string`            | `"256M"`                  |    no    |
| `max_instance_count`           | Maximum number of function instances (cost ceiling).                              | `number`            | `100`                     |    no    |
| `ingress_settings`             | `ALLOW_INTERNAL_ONLY`, `ALLOW_INTERNAL_AND_GCLB` or `ALLOW_ALL`.                  | `string`            | `"ALLOW_INTERNAL_ONLY"`   |    no    |
| `service_account_email`        | Service account the function runs as. `null` uses the default (over-privileged) SA. | `string`          | `null`                    |    no    |
| `environment_variables`        | Non-sensitive environment variables (plaintext).                                  | `map(string)`       | `{}`                      |    no    |
| `secret_environment_variables` | Secret Manager secrets exposed as environment variables.                          | `list(object({...}))` | `[]`                    |    no    |
| `labels`                       | Labels applied to the function.                                                   | `map(string)`       | `{}`                      |    no    |

`secret_environment_variables` entries take the shape:

```hcl
{
  key        = string           # environment variable name
  secret     = string           # Secret Manager secret ID
  version    = optional(string) # defaults to "latest"
  project_id = optional(string) # defaults to var.project_id
}
```

## Outputs

| Name   | Description                                              |
|--------|----------------------------------------------------------|
| `id`   | Identifier of the Cloud Function.                       |
| `name` | Name of the Cloud Function.                             |
| `uri`  | URI of the underlying Cloud Run service.                |

## Testing

```sh
terraform init -backend=false
terraform test
```

The suite uses a mocked provider, so it needs no Google Cloud credentials and
makes no API calls.

## License

[MIT](LICENSE)
