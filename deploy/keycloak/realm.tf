# SRE Operations Realm
# Creates the realm if it doesn't exist, or imports existing realm

resource "keycloak_realm" "sre_ops" {
  realm   = var.keycloak_realm
  enabled = true

  # Display settings
  display_name      = "SRE Operations"
  display_name_html = "<b>SRE Operations</b>"

  # Login settings
  login_with_email_allowed = true
  duplicate_emails_allowed = false
  reset_password_allowed   = true
  remember_me              = true

  # Token settings - match OIDC client
  access_token_lifespan    = "1h"
  sso_session_idle_timeout = "1h"
  sso_session_max_lifespan = "10h"

  # Security settings
  ssl_required = "external"

  # Theme (optional - can customize)
  # login_theme   = "keycloak"
  # account_theme = "keycloak"
  # admin_theme   = "keycloak"
  # email_theme   = "keycloak"
}

# SRE Team Group
resource "keycloak_group" "sre_team" {
  realm_id = keycloak_realm.sre_ops.id
  name     = "sre-team"
}
