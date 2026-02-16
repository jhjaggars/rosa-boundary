# Keycloak Terraform Quick Start

## What You Need

### 1. Running Keycloak Instance ✅
- URL: `https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com`
- Must be accessible from your workstation

### 2. Admin Credentials 🔑
- **Username**: (e.g., `admin`)
- **Password**: Get from OpenShift secret or deployment docs

### 3. Local Tools 🛠️
- Terraform >= 1.0
- curl (for testing)
- jq (optional, for JSON parsing)

## Quick Setup

```bash
# 1. Get admin password (if on OpenShift)
oc get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.password}' | base64 -d

# 2. Test Keycloak is accessible
curl -s https://keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/master/.well-known/openid-configuration | jq '.issuer'

# 3. Configure Terraform
cd deploy/keycloak
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your admin password

# 4. Deploy
terraform init
terraform plan   # Review changes
terraform apply  # Type 'yes' to confirm
```

## What Gets Created

- ✅ Realm: `sre-ops`
- ✅ Group: `sre-team`
- ✅ OIDC Client: `aws-sre-access` (with PKCE enabled)
- ✅ Protocol Mappers: groups, username, audience

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't reach Keycloak | Verify URL, check network connectivity |
| Authentication failed | Verify admin credentials, check realm is `master` |
| Realm already exists | Import it: `terraform import keycloak_realm.sre_ops sre-ops` |

## Next Steps

After successful deployment:
1. Add users to `sre-team` group in Keycloak UI
2. Get certificate thumbprint for AWS
3. Configure AWS OIDC provider (see `../regional/OIDC_SETUP.md`)

## Detailed Documentation

- **Prerequisites**: See `PREREQUISITES.md` for detailed setup
- **Keycloak Guide**: See `README.md` for complete documentation
- **AWS Integration**: See `../regional/OIDC_SETUP.md`
