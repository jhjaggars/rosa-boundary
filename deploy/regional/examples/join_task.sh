#!/bin/bash
set -e

# Script to connect to a running Fargate task via ECS Exec
# Usage: ./join_task.sh <task-id>

TASK_ID="${1}"

if [ -z "$TASK_ID" ]; then
  echo "Usage: $0 <task-id>"
  echo ""
  echo "Example:"
  echo "  $0 394399c601f94548bedb65d5a90f30c6"
  echo ""
  echo "List running tasks:"
  echo "  aws ecs list-tasks --cluster rosa-boundary-dev --desired-status RUNNING"
  exit 1
fi

# AWS configuration
PROFILE="${AWS_PROFILE:-scuppett-dev}"
REGION="${AWS_REGION:-us-east-2}"

# Get cluster name from Terraform outputs
cd "$(dirname "$0")/.."
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)

echo "Connecting to task..."
echo "  Task ID: $TASK_ID"
echo "  Cluster: $CLUSTER_NAME"
echo "  AWS Profile: $PROFILE"
echo "  AWS Region: $REGION"
echo ""

# Verify task is running
TASK_STATUS=$(aws ecs describe-tasks \
  --profile "$PROFILE" \
  --region "$REGION" \
  --cluster "$CLUSTER_NAME" \
  --tasks "$TASK_ID" \
  --query 'tasks[0].lastStatus' \
  --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$TASK_STATUS" != "RUNNING" ]; then
  echo "ERROR: Task $TASK_ID is not running (status: $TASK_STATUS)"
  echo ""
  echo "List running tasks:"
  echo "  AWS_PROFILE=$PROFILE AWS_REGION=$REGION aws ecs list-tasks --cluster $CLUSTER_NAME --desired-status RUNNING"
  exit 1
fi

echo "Task is running. Connecting as sre user..."
echo ""

# Connect via ECS Exec as sre user
AWS_PROFILE="$PROFILE" AWS_REGION="$REGION" aws ecs execute-command \
  --cluster "$CLUSTER_NAME" \
  --task "$TASK_ID" \
  --container rosa-boundary \
  --interactive \
  --command '/usr/bin/su - sre'
