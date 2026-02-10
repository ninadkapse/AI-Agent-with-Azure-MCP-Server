#!/bin/bash
# =============================================================================
# setup-permissions.sh
# Post-deployment script to configure Entra ID API permissions for Azure MCP Server
#
# This script:
#   1. Adds the Mcp.Tools.ReadWrite API permission to the client app registration
#   2. Adds all downstream API permissions to the server app registration
#   3. Grants admin consent for the permissions
#
# Prerequisites:
#   - Azure CLI installed and authenticated (az login)
#   - Run 'azd env get-values' first to get the required values
#
# Usage:
#   ./scripts/setup-permissions.sh
# =============================================================================

set -e

echo "=============================================="
echo "Azure MCP Server - Entra ID Permission Setup"
echo "=============================================="

# Load azd environment values
if command -v azd &> /dev/null; then
    echo "Loading azd environment values..."
    eval "$(azd env get-values 2>/dev/null)" || true
fi

# Prompt for values if not set
if [ -z "$ENTRA_APP_SERVER_CLIENT_ID" ]; then
    read -p "Enter Server App Registration Client ID (ENTRA_APP_SERVER_CLIENT_ID): " ENTRA_APP_SERVER_CLIENT_ID
fi

if [ -z "$ENTRA_APP_CLIENT_CLIENT_ID" ]; then
    read -p "Enter Client App Registration Client ID (ENTRA_APP_CLIENT_CLIENT_ID): " ENTRA_APP_CLIENT_CLIENT_ID
fi

if [ -z "$ENTRA_APP_SERVER_SCOPE_ID" ]; then
    read -p "Enter Server App Scope ID (ENTRA_APP_SERVER_SCOPE_ID): " ENTRA_APP_SERVER_SCOPE_ID
fi

echo ""
echo "Server App Client ID: $ENTRA_APP_SERVER_CLIENT_ID"
echo "Client App Client ID: $ENTRA_APP_CLIENT_CLIENT_ID"
echo "Server App Scope ID:  $ENTRA_APP_SERVER_SCOPE_ID"
echo ""

# =============================================================================
# Step 1: Add Mcp.Tools.ReadWrite permission to Client App
# =============================================================================
echo "--- Step 1: Adding Mcp.Tools.ReadWrite permission to Client App ---"
az ad app permission add \
    --id "$ENTRA_APP_CLIENT_CLIENT_ID" \
    --api "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api-permissions "${ENTRA_APP_SERVER_SCOPE_ID}=Scope" \
    2>/dev/null && echo "  ✓ Added Mcp.Tools.ReadWrite scope to client app" || echo "  ⚠ Permission may already exist"

# =============================================================================
# Step 2: Add downstream API permissions to Server App
# These permissions allow the Azure MCP Server to call downstream Azure APIs
# on behalf of the signed-in user.
# =============================================================================
echo ""
echo "--- Step 2: Adding downstream API permissions to Server App ---"

# Azure Resource Manager (ARM) — required by most tools
echo "  Adding Azure Resource Manager (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "797f4846-ba00-4fd7-ba43-dac1f8f63013" \
    --api-permissions "41094075-9dad-400e-a0bd-54e686782033=Scope" \
    2>/dev/null && echo "    ✓ Azure Resource Manager" || echo "    ⚠ May already exist"

# Azure Storage
echo "  Adding Azure Storage (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "e406a681-f3d4-42a8-90b6-c2b029497af1" \
    --api-permissions "03e0da56-190b-40ad-a80c-ea378c433f7f=Scope" \
    2>/dev/null && echo "    ✓ Azure Storage" || echo "    ⚠ May already exist"

# Azure Key Vault
echo "  Adding Azure Key Vault (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "cfa8b339-82a2-471a-a3c9-0fc0be7a4093" \
    --api-permissions "f53da476-18e3-4152-8e01-aec403e6edc0=Scope" \
    2>/dev/null && echo "    ✓ Azure Key Vault" || echo "    ⚠ May already exist"

# Azure Data Explorer (Kusto)
echo "  Adding Azure Data Explorer (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "2746ea77-4702-4b45-80ca-3c97e680e8b7" \
    --api-permissions "00d678f0-da44-4b12-a6d6-c98bcfd1c5fe=Scope" \
    2>/dev/null && echo "    ✓ Azure Data Explorer" || echo "    ⚠ May already exist"

# Azure OSS RDBMS AAD (PostgreSQL/MySQL)
echo "  Adding Azure PostgreSQL/MySQL (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "123cd850-d9df-40bd-94d5-c9f07b7fa203" \
    --api-permissions "cef99a3a-4cd3-4408-8143-4375d1e38a17=Scope" \
    2>/dev/null && echo "    ✓ Azure PostgreSQL/MySQL" || echo "    ⚠ May already exist"

# Azure CLI Extension (CLI Generate)
echo "  Adding Azure CLI Extension (Azclis.Intelligent.All)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "a5ede409-60d3-4a6c-93e6-eb2e7271e8e3" \
    --api-permissions "94f3aa7c-b710-40be-83e4-8b5de364a323=Scope" \
    2>/dev/null && echo "    ✓ Azure CLI Extension" || echo "    ⚠ May already exist"

# Azure App Configuration (all scopes)
echo "  Adding Azure App Configuration (all scopes)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "35ffadb3-7fc1-497e-b61b-381d28e744cc" \
    --api-permissions "8d17f7f7-030c-4b57-8129-cfb5a16433cd=Scope 77967a14-4f88-4960-84da-e8f71f761ac2=Scope 08eeff12-9b4a-4273-b3d9-ff8a13c32645=Scope 5970d132-a862-421f-9352-8ed18f833d78=Scope ea601552-5fd3-4792-9dfc-e85be5a6827c=Scope 28bb462a-d940-4cbe-afeb-281756df9af8=Scope" \
    2>/dev/null && echo "    ✓ Azure App Configuration" || echo "    ⚠ May already exist"

# Azure Event Hubs
echo "  Adding Azure Event Hubs (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "80369ed6-5f11-4dd9-bef3-692475845e77" \
    --api-permissions "7d388411-3845-4cfc-aa69-33192f4b9735=Scope" \
    2>/dev/null && echo "    ✓ Azure Event Hubs" || echo "    ⚠ May already exist"

# Azure Service Bus
echo "  Adding Azure Service Bus (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "80a10ef9-8168-493d-abf9-3297c4ef6e3c" \
    --api-permissions "40e16207-c5fd-4916-8ca4-64565f2367ca=Scope" \
    2>/dev/null && echo "    ✓ Azure Service Bus" || echo "    ⚠ May already exist"

# Azure AI Search
echo "  Adding Azure AI Search (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "880da380-985e-4198-81b9-e05b1cc53158" \
    --api-permissions "a4165a31-5d9e-4120-bd1e-9d88c66fd3b8=Scope" \
    2>/dev/null && echo "    ✓ Azure AI Search" || echo "    ⚠ May already exist"

# Azure Cognitive Services (Speech)
echo "  Adding Azure Cognitive Services Speech (user_impersonation)..."
az ad app permission add \
    --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --api "7d312290-28c8-473c-a0ed-8e53749b6d6d" \
    --api-permissions "5f1e8914-a52b-429f-9324-91b92b81adaf=Scope" \
    2>/dev/null && echo "    ✓ Azure Cognitive Services (Speech)" || echo "    ⚠ May already exist"

# =============================================================================
# Step 3: Grant admin consent
# =============================================================================
echo ""
echo "--- Step 3: Granting admin consent ---"
echo "  Granting admin consent for server app..."
az ad app permission admin-consent --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    2>/dev/null && echo "    ✓ Admin consent granted for server app" || echo "    ⚠ Admin consent may require tenant admin privileges"

echo "  Granting admin consent for client app..."
az ad app permission admin-consent --id "$ENTRA_APP_CLIENT_CLIENT_ID" \
    2>/dev/null && echo "    ✓ Admin consent granted for client app" || echo "    ⚠ Admin consent may require tenant admin privileges"

# =============================================================================
# Step 4: Set Identifier URI on server app
# =============================================================================
echo ""
echo "--- Step 4: Setting Identifier URI on Server App ---"
az ad app update --id "$ENTRA_APP_SERVER_CLIENT_ID" \
    --identifier-uris "api://$ENTRA_APP_SERVER_CLIENT_ID" \
    2>/dev/null && echo "  ✓ Identifier URI set to api://$ENTRA_APP_SERVER_CLIENT_ID" || echo "  ⚠ Identifier URI may already be set"

echo ""
echo "=============================================="
echo "✅ Entra ID Permission Setup Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "  1. Go to Azure Portal → Client App ($ENTRA_APP_CLIENT_CLIENT_ID) → API permissions"
echo "     Verify 'Mcp.Tools.ReadWrite' permission is listed and granted"
echo "  2. Go to Azure Portal → Server App ($ENTRA_APP_SERVER_CLIENT_ID) → API permissions"
echo "     Verify all downstream API permissions are listed and granted"
echo "  3. Configure the Power Apps custom connector (see README.md)"
echo ""
