terraform {
  required_version = ">= 1.0"

  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4.0"
    }
  }
}

provider "keycloak" {
  client_id = var.keycloak_admin_client_id
  username  = var.keycloak_admin_username
  password  = var.keycloak_admin_password
  url       = var.keycloak_url
  realm     = var.keycloak_admin_realm # Authenticate against master realm for admin operations
}

# AWS SRE Access OIDC Client
resource "keycloak_openid_client" "aws_sre" {
  realm_id  = var.keycloak_realm
  client_id = "aws-sre-access"

  name    = "AWS SRE Access"
  enabled = true

  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false

  # PKCE enforcement for public clients
  pkce_code_challenge_method = "S256"

  # Redirect URIs for local callback server
  valid_redirect_uris = [
    "http://localhost:8400/callback",
    "http://127.0.0.1:8400/callback"
  ]

  # Token settings - match AWS session duration
  access_token_lifespan = "3600" # 1 hour

  # OAuth scopes
  full_scope_allowed = false
}

# Protocol mapper for groups claim
resource "keycloak_openid_group_membership_protocol_mapper" "aws_sre_groups" {
  realm_id  = var.keycloak_realm
  client_id = keycloak_openid_client.aws_sre.id
  name      = "groups"

  claim_name = "groups"
  full_path  = false
}

# Protocol mapper for preferred_username
resource "keycloak_openid_user_property_protocol_mapper" "aws_sre_username" {
  realm_id  = var.keycloak_realm
  client_id = keycloak_openid_client.aws_sre.id
  name      = "preferred_username"

  user_property = "username"
  claim_name    = "preferred_username"
}

# Audience mapper to ensure client_id is in aud claim
resource "keycloak_openid_audience_protocol_mapper" "aws_sre_audience" {
  realm_id  = var.keycloak_realm
  client_id = keycloak_openid_client.aws_sre.id
  name      = "audience"

  included_client_audience = "aws-sre-access"
}
