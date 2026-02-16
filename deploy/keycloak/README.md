# Keycloak OIDC Integration for AWS

This Terraform configuration creates a Keycloak OIDC client for AWS federation, allowing users to authenticate with Keycloak and receive temporary AWS credentials.

## Prerequisites

1. **Keycloak Instance**: Running Keycloak server with an existing realm
2. **Terraform**: >= 1.0
3. **Keycloak Admin Credentials**: Username and password for Terraform provider
4. **sre-team Group**: Users must be members of this group to assume the AWS role

## Configuration

1. **Copy example configuration:**

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. **Edit `terraform.tfvars`:**

```hcl
keycloak_url              = "https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com"
keycloak_realm            = "sre-ops"
keycloak_admin_client_id  = "admin-cli"
keycloak_admin_username   = "admin"
keycloak_admin_password   = "YOUR_ADMIN_PASSWORD"
```

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Created Resources

### OIDC Client: `aws-sre-access`

- **Access Type**: PUBLIC (for CLI with PKCE)
- **PKCE Method**: S256 (required)
- **Redirect URIs**:
  - `http://localhost:8400/callback`
  - `http://127.0.0.1:8400/callback`
- **Token Lifetime**: 3600 seconds (1 hour)

### Protocol Mappers

1. **groups**: Maps user group membership to `groups` claim
2. **preferred_username**: Maps username to `preferred_username` claim
3. **audience**: Ensures `aws-sre-access` is in the `aud` claim

## User Configuration

### Required Group Membership

Users must be members of the `sre-team` group in Keycloak. To add a user to the group:

1. Navigate to **Users** in Keycloak admin console
2. Select the user
3. Go to **Groups** tab
4. Click **Join Group**
5. Select `sre-team`

### Create sre-team Group (if not exists)

```bash
# Using Keycloak CLI (kcadm.sh)
kcadm.sh create groups -r sre-ops -s name=sre-team
```

Or via Terraform (add to `main.tf`):

```hcl
resource "keycloak_group" "sre_team" {
  realm_id = var.keycloak_realm
  name     = "sre-team"
}
```

## Testing

After deployment, test the OIDC client configuration:

### 1. Verify client exists

```bash
terraform output client_id
# Output: aws-sre-access
```

### 2. Check OIDC endpoints

```bash
terraform output authorization_endpoint
terraform output token_endpoint
terraform output issuer_url
```

### 3. Test authentication flow

Use the `sre-auth.sh` tool (see `../../tools/sre-auth/README.md`):

```bash
cd ../../tools/sre-auth
./sre-auth.sh --role arn:aws:iam::ACCOUNT:role/rosa-boundary-dev-oidc-sre-role
```

## Integration with AWS

After deploying this Keycloak configuration, you need to:

1. **Obtain Keycloak TLS certificate thumbprint**:

```bash
openssl s_client -connect keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com:443 \
  -servername keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com < /dev/null 2>/dev/null \
  | openssl x509 -fingerprint -sha1 -noout | sed 's/://g' | awk -F= '{print tolower($2)}'
```

2. **Configure AWS Terraform** (in `../regional/`):

Add to `terraform.tfvars`:

```hcl
keycloak_thumbprint = "THUMBPRINT_FROM_STEP_1"
```

3. **Deploy AWS OIDC provider**:

```bash
cd ../regional
terraform apply
```

## Outputs

- `client_id`: OIDC client ID (aws-sre-access)
- `authorization_endpoint`: OAuth authorization endpoint
- `token_endpoint`: Token exchange endpoint
- `issuer_url`: OIDC issuer URL (used by AWS OIDC provider)

## Troubleshooting

### Client not working

- Verify redirect URIs exactly match `http://localhost:8400/callback`
- Check that PKCE is enabled with S256 method
- Ensure `groups` mapper is configured

### Token validation errors

- Verify `audience` mapper includes client ID in `aud` claim
- Check token lifetime matches AWS session duration

### Permission denied

- Confirm user is member of `sre-team` group
- Verify group mapper is configured and includes group membership in token
