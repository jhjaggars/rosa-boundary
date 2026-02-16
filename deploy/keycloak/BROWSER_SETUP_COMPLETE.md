# Keycloak OIDC Configuration - Browser Setup Complete

Successfully configured Keycloak OIDC integration for AWS IAM federation using Playwright browser automation.

## What Was Configured

### 1. Group Created: `sre-team` ✅

- **Location**: sre-ops realm → Groups
- **Purpose**: Users must be members of this group to assume the AWS OIDC role
- **Next Step**: Add users to this group via Keycloak admin console

### 2. OIDC Client Created: `aws-sre-access` ✅

**General Settings:**
- **Client ID**: `aws-sre-access`
- **Name**: AWS SRE Access
- **Description**: OIDC client for AWS IAM federation via AssumeRoleWithWebIdentity
- **Protocol**: OpenID Connect
- **Client Type**: PUBLIC (for CLI with PKCE)

**Capability Configuration:**
- **Client Authentication**: OFF (public client)
- **Standard Flow**: ENABLED (authorization code flow)
- **Direct Access Grants**: DISABLED (no password grants)
- **Implicit Flow**: DISABLED (not secure for public clients)
- **PKCE Method**: **S256** ✅ (required for security)

**Access Settings:**
- **Valid Redirect URIs**:
  - `http://localhost:8400/callback`
  - `http://127.0.0.1:8400/callback`
- **Web Origins**: Auto-configured from redirect URIs

### 3. Protocol Mappers Configured ✅

#### Mapper 1: `groups` (Group Membership)
- **Type**: Group Membership
- **Token Claim Name**: `groups`
- **Full Group Path**: OFF (just group names)
- **Add to ID Token**: ON ✅
- **Add to Access Token**: ON ✅
- **Add to UserInfo**: ON ✅
- **Add to Token Introspection**: ON ✅
- **Purpose**: Maps user group membership to `groups` claim for AWS OIDC role condition

#### Mapper 2: `audience` (Audience)
- **Type**: Audience
- **Included Custom Audience**: `aws-sre-access`
- **Add to ID Token**: ON ✅
- **Add to Access Token**: ON ✅
- **Add to Token Introspection**: ON ✅
- **Purpose**: Ensures client ID is in `aud` claim for AWS OIDC provider validation

## Screenshot

Configuration verified - see `keycloak-mappers-configured.png`

## OIDC Endpoints

Based on the configuration:

- **Issuer URL**: `https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/sre-ops`
- **Authorization Endpoint**: `https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/sre-ops/protocol/openid-connect/auth`
- **Token Endpoint**: `https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/sre-ops/protocol/openid-connect/token`

## Token Structure

When a user authenticates, the ID token will include:

```json
{
  "iss": "https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/sre-ops",
  "aud": "aws-sre-access",
  "sub": "user-uuid",
  "preferred_username": "username",
  "groups": ["sre-team", "other-groups"],
  ...
}
```

## AWS OIDC Provider Configuration

Now you can configure the AWS OIDC provider with these values:

1. **Get Certificate Thumbprint**:
   ```bash
   openssl s_client -connect keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com:443 \
     -servername keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com < /dev/null 2>/dev/null \
     | openssl x509 -fingerprint -sha1 -noout | sed 's/://g' | awk -F= '{print tolower($2)}'
   ```

2. **Configure AWS Terraform** (`deploy/regional/terraform.tfvars`):
   ```hcl
   keycloak_thumbprint = "PASTE_THUMBPRINT_HERE"
   ```

3. **Deploy AWS Infrastructure**:
   ```bash
   cd deploy/regional
   terraform apply
   ```

## Next Steps

### 1. Add Users to sre-team Group

In Keycloak admin console:
1. Navigate to **Users** in sre-ops realm
2. Select a user
3. Go to **Groups** tab
4. Click **Join Group**
5. Select `sre-team`
6. Click **Join**

### 2. Deploy AWS OIDC Provider

Follow the instructions in `../regional/OIDC_SETUP.md`

### 3. Test Authentication

Use the `sre-auth.sh` tool:

```bash
cd ../../tools/sre-auth

# Get role ARN from Terraform output
cd ../../deploy/regional
ROLE_ARN=$(terraform output -raw oidc_sre_role_arn)

# Authenticate
cd ../../tools/sre-auth
eval $(./sre-auth.sh --role $ROLE_ARN)

# Test ECS access
aws ecs list-clusters
```

## Verification Checklist

- [x] sre-ops realm exists
- [x] sre-team group created
- [x] aws-sre-access client created
- [x] PKCE enabled with S256
- [x] Redirect URIs configured
- [x] Group membership mapper configured
- [x] Audience mapper configured
- [ ] Certificate thumbprint obtained
- [ ] AWS OIDC provider deployed
- [ ] Users added to sre-team group
- [ ] Authentication tested with sre-auth.sh

## Configuration vs. Terraform

This browser setup achieves the same result as the Terraform configuration in `deploy/keycloak/`, but using the Keycloak admin UI instead. Both approaches are valid:

- **Browser Setup** (this approach): Good for one-time setup, visual confirmation
- **Terraform Setup**: Good for reproducibility, version control, automation

The configuration is now complete and ready for AWS integration!
