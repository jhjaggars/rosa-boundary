# Keycloak Terraform Prerequisites

This document outlines everything you need before running the Keycloak Terraform configuration.

## Required Infrastructure

### 1. Running Keycloak Instance

You need a Keycloak server already deployed and accessible:

- **Default URL**: `https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com`
- **Required**: Keycloak must be accessible from your workstation
- **Version**: Should be compatible with the provider (Keycloak 15+)

#### Verify Keycloak Access

```bash
# Check that Keycloak is reachable
curl -s https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/health | jq

# Or test the OIDC discovery endpoint
curl -s https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/master/.well-known/openid-configuration | jq '.issuer'
```

## Required Credentials

### 2. Admin Credentials

You need credentials with permission to create realms and clients:

| Credential | Description | How to Get |
|------------|-------------|------------|
| **Admin Username** | Keycloak admin user | Usually set during Keycloak installation |
| **Admin Password** | Password for admin user | Set during installation or via admin console |
| **Admin Realm** | Realm to authenticate against | Usually `master` (default) |
| **Admin Client ID** | Client for API access | Usually `admin-cli` (built-in) |

#### Get Admin Credentials

**If Keycloak is deployed on OpenShift:**

```bash
# Get admin password from secret
oc get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.password}' | base64 -d

# Get admin username (usually 'admin')
oc get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.username}' | base64 -d
```

**If Keycloak is deployed elsewhere:**
- Check deployment documentation
- Look for environment variables: `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD`
- Check container logs for initial admin credentials

### 3. Test Admin Access

Verify you can authenticate with admin credentials:

```bash
# Get access token using admin credentials
curl -s -X POST \
  "https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=YOUR_PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq '.access_token' -r
```

If you get a token, your credentials work!

## Local Tools

### 4. Terraform

Install Terraform >= 1.0:

```bash
# macOS
brew install terraform

# Linux
# Download from https://www.terraform.io/downloads

# Verify installation
terraform version
```

### 5. Optional: jq for JSON parsing

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq  # Debian/Ubuntu
sudo yum install jq      # RHEL/CentOS
```

## What This Terraform Creates

The configuration will create:

1. **Realm**: `sre-ops` (if using realm.tf)
2. **Group**: `sre-team` (if using realm.tf)
3. **OIDC Client**: `aws-sre-access`
   - With PKCE enabled
   - With group membership mapper
   - With audience mapper
4. **Protocol Mappers**: groups, preferred_username, audience

## Configuration Steps

### 1. Copy Example Configuration

```bash
cd deploy/keycloak
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit terraform.tfvars

Update with your actual values:

```hcl
keycloak_url              = "https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com"
keycloak_realm            = "sre-ops"        # Realm to create/manage
keycloak_admin_realm      = "master"        # Usually 'master' for admin operations
keycloak_admin_client_id  = "admin-cli"     # Default admin client
keycloak_admin_username   = "admin"         # Your admin username
keycloak_admin_password   = "ACTUAL_PASSWORD"  # Your admin password
```

### 3. Initialize Terraform

```bash
terraform init
```

This downloads the Keycloak provider (~4.0).

### 4. Plan the Changes

```bash
terraform plan
```

Review what will be created:
- 1 realm (sre-ops)
- 1 group (sre-team)
- 1 OIDC client (aws-sre-access)
- 3 protocol mappers

### 5. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

## Troubleshooting

### "Error: Failed to create realm"

**Cause**: Realm already exists, or insufficient permissions

**Solutions**:
1. **Import existing realm**:
   ```bash
   terraform import keycloak_realm.sre_ops sre-ops
   ```

2. **Or use existing realm** - Comment out `realm.tf` and ensure `sre-ops` realm exists manually

### "Error: Authentication failed"

**Cause**: Wrong credentials or admin realm

**Solutions**:
1. Verify credentials work (see "Test Admin Access" above)
2. Check `keycloak_admin_realm` is correct (usually `master`)
3. Ensure user has admin privileges in the master realm

### "Error: Connection refused"

**Cause**: Cannot reach Keycloak instance

**Solutions**:
1. Verify Keycloak URL is correct
2. Check network connectivity: `curl -I https://keycloak-host`
3. Check firewall rules allow HTTPS access
4. If using OpenShift routes, verify route exists: `oc get routes -n keycloak`

### "Error: Provider version constraint"

**Cause**: Incompatible Terraform version

**Solution**: Upgrade Terraform to >= 1.0

## If Realm Already Exists

If the `sre-ops` realm already exists in Keycloak:

**Option A: Import the realm**

```bash
terraform import keycloak_realm.sre_ops sre-ops
terraform import keycloak_group.sre_team sre-ops/GROUP_ID  # Get GROUP_ID from Keycloak
```

**Option B: Don't manage the realm**

Remove or comment out `realm.tf` and manually ensure:
- Realm `sre-ops` exists
- Group `sre-team` exists in that realm

Then only manage the OIDC client resources.

## Next Steps

After successful deployment:

1. **Verify client was created**:
   - Log into Keycloak admin console
   - Navigate to Clients in sre-ops realm
   - Find `aws-sre-access` client

2. **Add users to sre-team group**:
   - Navigate to Users
   - Select a user
   - Click "Groups" tab
   - Join the `sre-team` group

3. **Get OIDC endpoints**:
   ```bash
   terraform output
   ```

4. **Proceed to AWS configuration** (see `../regional/OIDC_SETUP.md`)

## Summary Checklist

- [ ] Keycloak instance is running and accessible
- [ ] Have admin username and password
- [ ] Admin credentials tested and working
- [ ] Terraform >= 1.0 installed
- [ ] Configuration file created (`terraform.tfvars`)
- [ ] `terraform init` completed successfully
- [ ] `terraform plan` shows expected resources
- [ ] Ready to run `terraform apply`
