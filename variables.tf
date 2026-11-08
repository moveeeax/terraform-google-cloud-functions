variable "project_id" {
  description = "ID of the project in which to create the function."
  type        = string
}

variable "name" {
  description = "Name of the Cloud Function."
  type        = string
}

variable "location" {
  description = "Region in which to deploy the function."
  type        = string
}

variable "runtime" {
  description = "Runtime to run the function, e.g. nodejs22, python312 or go123. Pick a runtime that is still supported; Google stops patching deprecated runtimes and eventually blocks deploys against them."
  type        = string
  default     = "nodejs22"
}

variable "entry_point" {
  description = "Name of the function (as defined in source code) that is executed."
  type        = string
}

variable "source_bucket" {
  description = "Name of the Cloud Storage bucket holding the source archive."
  type        = string
}

variable "source_object" {
  description = "Object path of the source archive within the bucket."
  type        = string
}

variable "available_memory" {
  description = "Memory available to the function, e.g. \"256M\"."
  type        = string
  default     = "256M"
}

variable "max_instance_count" {
  description = "Maximum number of function instances. Acts as the cost ceiling for the function: every concurrent instance is billed, so keep this as low as the workload allows."
  type        = number
  default     = 100

  validation {
    condition     = var.max_instance_count >= 1
    error_message = "max_instance_count must be at least 1."
  }
}

variable "ingress_settings" {
  description = "Which networks may reach the function endpoint. One of ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB or ALLOW_ALL. Defaults to ALLOW_INTERNAL_ONLY; set ALLOW_ALL only for functions that are meant to be callable from the public internet."
  type        = string
  default     = "ALLOW_INTERNAL_ONLY"

  validation {
    condition     = contains(["ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB", "ALLOW_ALL"], var.ingress_settings)
    error_message = "ingress_settings must be one of ALLOW_INTERNAL_ONLY, ALLOW_INTERNAL_AND_GCLB or ALLOW_ALL."
  }
}

variable "service_account_email" {
  description = "Email of the service account the function runs as. Leaving this null makes the function run as the App Engine / Compute default service account, which holds project-wide Editor — supply a dedicated least-privilege service account instead."
  type        = string
  default     = null

  validation {
    condition     = var.service_account_email == null || can(regex("^[^@[:space:]]+@[^@[:space:]]+$", var.service_account_email))
    error_message = "service_account_email must be null or a service account email address."
  }
}

variable "environment_variables" {
  description = "Non-sensitive environment variables passed to the function at runtime. These are stored in plaintext in Terraform state and are readable by anyone with view access to the function — use secret_environment_variables for credentials."
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret Manager secrets exposed to the function as environment variables. The value is resolved by the platform at runtime, so it never lands in Terraform state. project_id defaults to the function's project."
  type = list(object({
    key        = string
    secret     = string
    version    = optional(string, "latest")
    project_id = optional(string)
  }))
  default = []

  validation {
    condition     = length(distinct([for s in var.secret_environment_variables : s.key])) == length(var.secret_environment_variables)
    error_message = "Each secret_environment_variables entry must use a distinct key."
  }
}

variable "labels" {
  description = "Labels applied to the function."
  type        = map(string)
  default     = {}
}

variable "vpc_connector" {
  description = "Full resource name of the Serverless VPC Access connector the function sends egress through, projects/<project>/locations/<region>/connectors/<name> (the id of a google_vpc_access_connector). Null means no VPC access."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_connector == null || can(regex("^projects/[^/]+/locations/[^/]+/connectors/[^/]+$", var.vpc_connector))
    error_message = "vpc_connector must be null or a full connector name: projects/<project>/locations/<region>/connectors/<name>."
  }
}

variable "vpc_connector_egress_settings" {
  description = "Which outbound traffic goes through vpc_connector: PRIVATE_RANGES_ONLY or ALL_TRAFFIC. Null leaves the platform default. Requires vpc_connector."
  type        = string
  default     = null

  validation {
    condition     = var.vpc_connector_egress_settings == null || contains(["PRIVATE_RANGES_ONLY", "ALL_TRAFFIC"], coalesce(var.vpc_connector_egress_settings, "unset"))
    error_message = "vpc_connector_egress_settings must be null, PRIVATE_RANGES_ONLY or ALL_TRAFFIC."
  }
}
