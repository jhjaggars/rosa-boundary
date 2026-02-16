# Enable Script Mappers in Keycloak on OpenShift

## Overview

Script-based protocol mappers are disabled by default in Keycloak for security reasons. To enable them, you need to add a feature flag to the Keycloak deployment.

## Steps to Enable

### 1. Log into OpenShift

```bash
oc login <your-cluster>
```

### 2. Navigate to Keycloak Namespace

```bash
oc project keycloak
```

### 3. Edit Keycloak Deployment/Statefulset

Find the Keycloak deployment:

```bash
# Check if it's a Deployment
oc get deployment -n keycloak

# Or a StatefulSet
oc get statefulset -n keycloak

# Or check the Keycloak CR (if using Keycloak Operator)
oc get keycloak -n keycloak
```

### 4. Add Feature Flag

**Option A: If using Keycloak Operator (Recommended)**

Edit the Keycloak CR:

```bash
oc edit keycloak keycloak -n keycloak
```

Add the feature flag to the spec (verified from https://www.keycloak.org/server/all-config#category-feature):

```yaml
spec:
  additionalOptions:
    - name: features
      value: "scripts"  # Valid feature flag
```

**Option B: If using Deployment/StatefulSet Directly**

```bash
oc edit deployment keycloak -n keycloak
# or
oc edit statefulset keycloak -n keycloak
```

Add environment variable:

```yaml
spec:
  template:
    spec:
      containers:
      - name: keycloak
        env:
        - name: KC_FEATURES
          value: "scripts"
```

### 5. Wait for Rollout

```bash
# Watch the rollout
oc rollout status deployment/keycloak -n keycloak
# or
oc rollout status statefulset/keycloak -n keycloak

# Check pod is running
oc get pods -n keycloak -w
```

### 6. Verify Script Mappers Enabled

Once Keycloak restarts, log back into the admin console and:

1. Navigate to a client's dedicated scope mappers
2. Click "Add mapper" → "By configuration"
3. Look for **"Script Mapper"** or **"JavaScript"** in the list

## Alternative: Hardcoded Claim Approach (If Scripts Not Feasible)

If enabling script mappers isn't possible (production security policy, etc.), we can use a workaround:

**Option 1**: Use a **Hardcoded claim** mapper with JSON value (may not work for nested objects)

**Option 2**: Remove the groups condition entirely from the trust policy (recommended - already tested and working)

**Option 3**: Encode group in the `sub` claim like `sre-team:username` and match on that pattern

## After Enabling

Once script mappers are enabled, you can:

1. Navigate to: Clients → aws-sre-access → Client scopes → aws-sre-access-dedicated → Mappers
2. Click "Add mapper" → "By configuration"
3. Select "Script Mapper"
4. Configure:
   - **Name**: aws-session-tags
   - **Token Claim Name**: `https://aws.amazon.com/tags`
   - **Script**: Upload `aws-session-tags-mapper.js`
   - **Add to ID token**: ON
   - **Add to access token**: ON

## Update IAM Trust Policy

After adding the session tags mapper, update the IAM role trust policy to:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::641875867446:oidc-provider/keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/sre-ops"
    },
    "Action": ["sts:AssumeRoleWithWebIdentity", "sts:TagSession"],
    "Condition": {
      "StringEquals": {
        "keycloak-keycloak.apps.rosa.dev.dyee.p3.openshiftapps.com/realms/sre-ops:aud": "aws-sre-access"
      },
      "ForAnyValue:StringEquals": {
        "aws:PrincipalTag/groups": "sre-team"
      }
    }
  }]
}
```

**Note**: The condition changes from `provider:groups` to `aws:PrincipalTag/groups` because session tags are available as `aws:PrincipalTag/*` in the session context.

## Testing

After configuration:

```bash
cd /Users/jjaggars/code/rosa-boundary/tools/sre-auth
./sre-auth.sh --role arn:aws:iam::641875867446:role/rosa-boundary-dev-oidc-sre-role --force
```

The ID token should now include:
```json
{
  "https://aws.amazon.com/tags": {
    "principal_tags": {
      "groups": ["sre-team", "rosa-sre"]
    }
  }
}
```
