<#
.SYNOPSIS
    Post-deployment script to configure Entra ID API permissions for Azure MCP Server.

.DESCRIPTION
    This script:
      1. Adds the Mcp.Tools.ReadWrite API permission to the client app registration
      2. Adds all downstream API permissions to the server app registration
      3. Grants admin consent for the permissions
      4. Sets the Identifier URI on the server app

.NOTES
    Prerequisites:
      - Azure CLI installed and authenticated (az login)
      - Run 'azd env get-values' first to get the required values

    Usage:
      .\scripts\setup-permissions.ps1
#>

$ErrorActionPreference = "Continue"

Write-Host "=============================================="
Write-Host "Azure MCP Server - Entra ID Permission Setup"
Write-Host "=============================================="

# Load azd environment values
try {
    $azdValues = azd env get-values 2>$null
    if ($azdValues) {
        foreach ($line in $azdValues) {
            if ($line -match '^(\w+)="(.+)"$') {
                Set-Variable -Name $matches[1] -Value $matches[2]
            }
        }
        Write-Host "[OK] Loaded azd environment values."
    }
} catch {
    Write-Host "[WARN] Could not load azd values. Will prompt for input."
}

# Prompt for values if not set
if (-not $ENTRA_APP_SERVER_CLIENT_ID) {
    $ENTRA_APP_SERVER_CLIENT_ID = Read-Host "Enter Server App Registration Client ID (ENTRA_APP_SERVER_CLIENT_ID)"
}
if (-not $ENTRA_APP_CLIENT_CLIENT_ID) {
    $ENTRA_APP_CLIENT_CLIENT_ID = Read-Host "Enter Client App Registration Client ID (ENTRA_APP_CLIENT_CLIENT_ID)"
}
if (-not $ENTRA_APP_SERVER_SCOPE_ID) {
    $ENTRA_APP_SERVER_SCOPE_ID = Read-Host "Enter Server App Scope ID (ENTRA_APP_SERVER_SCOPE_ID)"
}

Write-Host ""
Write-Host "Server App Client ID: $ENTRA_APP_SERVER_CLIENT_ID"
Write-Host "Client App Client ID: $ENTRA_APP_CLIENT_CLIENT_ID"
Write-Host "Server App Scope ID:  $ENTRA_APP_SERVER_SCOPE_ID"
Write-Host ""

# Helper function
function Add-ApiPermission {
    param(
        [string]$AppId,
        [string]$ApiId,
        [string]$Permissions,
        [string]$DisplayName
    )
    Write-Host "  Adding $DisplayName..." -NoNewline
    $null = az ad app permission add --id $AppId --api $ApiId --api-permissions $Permissions 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host " [exists]" -ForegroundColor Yellow
    }
}

# Step 1: Add Mcp.Tools.ReadWrite permission to Client App
Write-Host "--- Step 1: Adding Mcp.Tools.ReadWrite permission to Client App ---"
Add-ApiPermission -AppId $ENTRA_APP_CLIENT_CLIENT_ID `
    -ApiId $ENTRA_APP_SERVER_CLIENT_ID `
    -Permissions "$($ENTRA_APP_SERVER_SCOPE_ID)=Scope" `
    -DisplayName "Mcp.Tools.ReadWrite"

# Step 2: Add downstream API permissions to Server App
Write-Host ""
Write-Host "--- Step 2: Adding downstream API permissions to Server App ---"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "797f4846-ba00-4fd7-ba43-dac1f8f63013" `
    -Permissions "41094075-9dad-400e-a0bd-54e686782033=Scope" `
    -DisplayName "Azure Resource Manager (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "e406a681-f3d4-42a8-90b6-c2b029497af1" `
    -Permissions "03e0da56-190b-40ad-a80c-ea378c433f7f=Scope" `
    -DisplayName "Azure Storage (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "cfa8b339-82a2-471a-a3c9-0fc0be7a4093" `
    -Permissions "f53da476-18e3-4152-8e01-aec403e6edc0=Scope" `
    -DisplayName "Azure Key Vault (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "2746ea77-4702-4b45-80ca-3c97e680e8b7" `
    -Permissions "00d678f0-da44-4b12-a6d6-c98bcfd1c5fe=Scope" `
    -DisplayName "Azure Data Explorer (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "123cd850-d9df-40bd-94d5-c9f07b7fa203" `
    -Permissions "cef99a3a-4cd3-4408-8143-4375d1e38a17=Scope" `
    -DisplayName "Azure PostgreSQL/MySQL (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "a5ede409-60d3-4a6c-93e6-eb2e7271e8e3" `
    -Permissions "94f3aa7c-b710-40be-83e4-8b5de364a323=Scope" `
    -DisplayName "Azure CLI Extension (Azclis.Intelligent.All)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "35ffadb3-7fc1-497e-b61b-381d28e744cc" `
    -Permissions "8d17f7f7-030c-4b57-8129-cfb5a16433cd=Scope 77967a14-4f88-4960-84da-e8f71f761ac2=Scope 08eeff12-9b4a-4273-b3d9-ff8a13c32645=Scope 5970d132-a862-421f-9352-8ed18f833d78=Scope ea601552-5fd3-4792-9dfc-e85be5a6827c=Scope 28bb462a-d940-4cbe-afeb-281756df9af8=Scope" `
    -DisplayName "Azure App Configuration (all scopes)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "80369ed6-5f11-4dd9-bef3-692475845e77" `
    -Permissions "7d388411-3845-4cfc-aa69-33192f4b9735=Scope" `
    -DisplayName "Azure Event Hubs (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "80a10ef9-8168-493d-abf9-3297c4ef6e3c" `
    -Permissions "40e16207-c5fd-4916-8ca4-64565f2367ca=Scope" `
    -DisplayName "Azure Service Bus (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "880da380-985e-4198-81b9-e05b1cc53158" `
    -Permissions "a4165a31-5d9e-4120-bd1e-9d88c66fd3b8=Scope" `
    -DisplayName "Azure AI Search (user_impersonation)"

Add-ApiPermission -AppId $ENTRA_APP_SERVER_CLIENT_ID `
    -ApiId "7d312290-28c8-473c-a0ed-8e53749b6d6d" `
    -Permissions "5f1e8914-a52b-429f-9324-91b92b81adaf=Scope" `
    -DisplayName "Azure Cognitive Services Speech (user_impersonation)"

# Step 3: Grant admin consent
Write-Host ""
Write-Host "--- Step 3: Granting admin consent ---"

Write-Host "  Granting admin consent for server app..." -NoNewline
$null = az ad app permission admin-consent --id $ENTRA_APP_SERVER_CLIENT_ID 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [may require tenant admin]" -ForegroundColor Yellow
}

Write-Host "  Granting admin consent for client app..." -NoNewline
$null = az ad app permission admin-consent --id $ENTRA_APP_CLIENT_CLIENT_ID 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [may require tenant admin]" -ForegroundColor Yellow
}

# Step 4: Set Identifier URI on server app
Write-Host ""
Write-Host "--- Step 4: Setting Identifier URI on Server App ---"
Write-Host "  Setting Identifier URI..." -NoNewline
$null = az ad app update --id $ENTRA_APP_SERVER_CLIENT_ID --identifier-uris "api://$ENTRA_APP_SERVER_CLIENT_ID" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host " [OK] api://$ENTRA_APP_SERVER_CLIENT_ID" -ForegroundColor Green
} else {
    Write-Host " [may already be set]" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================="
Write-Host "[DONE] Entra ID Permission Setup Complete!"
Write-Host "=============================================="
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Verify permissions in Azure Portal for both apps"
Write-Host "  2. Configure the Power Apps custom connector (see README.md)"
Write-Host ""
