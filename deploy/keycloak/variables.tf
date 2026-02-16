variable "keycloak_url" {
  description = "Keycloak server URL"
  type        = string
  default     = "https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com"
}

variable "keycloak_realm" {
  description = "Keycloak realm name to create/manage"
  type        = string
  default     = "sre-ops"
}

variable "keycloak_admin_realm" {
  description = "Realm to authenticate against (typically 'master' for admin operations)"
  type        = string
  default     = "master"
}

variable "keycloak_admin_client_id" {
  description = "Admin client ID for Keycloak API access"
  type        = string
  default     = "admin-cli"
}

variable "keycloak_admin_username" {
  description = "Admin username for Keycloak"
  type        = string
  sensitive   = true
}

variable "keycloak_admin_password" {
  description = "Admin password for Keycloak"
  type        = string
  sensitive   = true
}
