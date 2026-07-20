#!/bin/bash

# Ensure required arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./setup-azure.sh <APP_NAME> <YOUR_GITHUB_USER/YOUR_REPO_NAME>"
    exit 1
fi

APP_NAME=$1
REPO_NAME=$2

# 1. Create the Azure App Registration to serve as the service principal
echo "Creating App Registration..."
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)

# 2. Create the Service Principal for the App
echo "Creating Service Principal..."
az ad sp create --id "$APP_ID" > /dev/null

# 3. Configure the OIDC Federated Identity for the main branch.
# This credential is used when the pipeline runs on push to main
# (where terraform apply executes).
echo "Configuring OIDC Federated Identity (main branch)..."
az ad app federated-credential create --id "$APP_ID" --parameters \
  "{
    \"name\": \"github-actions-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO_NAME:ref:refs/heads/main\",
    \"description\": \"OIDC for GitHub Actions - main branch (apply)\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# 4. Configure the OIDC Federated Identity for pull requests.
# This credential is used when the pipeline runs on a PR
# (validate, format check, Checkov scan, and plan only -- no apply).
echo "Configuring OIDC Federated Identity (pull requests)..."
az ad app federated-credential create --id "$APP_ID" --parameters \
  "{
    \"name\": \"github-actions-pr\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO_NAME:pull_request\",
    \"description\": \"OIDC for GitHub Actions - pull requests (validate/plan only)\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# 5. Get the current subscription ID and tenant ID for convenience.
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# 6. Grant Contributor role on the subscription.
# NOTE: Contributor at subscription scope is broad. For a real production
# environment, scope this down to a specific Resource Group instead once
# one exists, following least-privilege principles.
echo "Assigning Contributor role..."
az role assignment create \
  --role "Contributor" \
  --assignee "$APP_ID" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" > /dev/null

echo "----------------------------------------------------"
echo "Setup complete. Save these three values as GitHub repository secrets"
echo "(Settings -> Secrets and variables -> Actions):"
echo ""
echo "AZURE_CLIENT_ID:       $APP_ID"
echo "AZURE_TENANT_ID:       $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "----------------------------------------------------"
