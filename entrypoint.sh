#!/bin/bash
set -e

# Switch OpenShift CLI version if OC_VERSION is set
if [ -n "${OC_VERSION}" ]; then
  if [ -x "/opt/openshift/${OC_VERSION}/oc" ]; then
    alternatives --set oc "/opt/openshift/${OC_VERSION}/oc"
  else
    echo "Warning: OC version ${OC_VERSION} not found, using default" >&2
  fi
fi

# Switch AWS CLI if AWS_CLI is set
if [ -n "${AWS_CLI}" ]; then
  case "${AWS_CLI}" in
    fedora)
      alternatives --set aws /usr/bin/aws
      ;;
    official|aws-official)
      alternatives --set aws /opt/aws-cli-official/v2/current/bin/aws
      ;;
    *)
      echo "Warning: Unknown AWS_CLI value '${AWS_CLI}', using default" >&2
      ;;
  esac
fi

# Execute the command (default: sleep infinity)
exec "${@:-sleep infinity}"
