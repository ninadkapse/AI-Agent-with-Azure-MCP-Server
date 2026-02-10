# AI Agent with Azure MCP Server for Copilot Studio

Deploy the [Azure MCP Server](https://github.com/microsoft/mcp) as a remote MCP server on Azure Container Apps and connect it to **Microsoft Copilot Studio** — enabling your AI agent to perform **all Azure operations** across **42+ Azure services**.

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────────────┐
│   Copilot Studio    │────▶│  Power Apps Custom    │────▶│  Azure Container App    │
│   Agent             │     │  Connector (OAuth)    │     │  (Azure MCP Server)     │
│                     │◀────│                       │◀────│  - All Azure Tools      │
└─────────────────────┘     └──────────────────────┘     │  - Managed Identity     │
                                                          └───────────┬─────────────┘
                                                                      │
                                                          ┌───────────▼─────────────┐
                                                          │   Azure Resources       │
                                                          │   (42+ Services)        │
                                                          └─────────────────────────┘
```

## Supported Azure Services (42+)

This agent exposes **all** Azure MCP tools, covering the following services:

| Service | Capabilities |
|---------|-------------|
| 🧮 **Microsoft Foundry** | AI model management, deployment, knowledge indexes, agents |
| 📊 **Azure Advisor** | Advisor recommendations |
| 🔎 **Azure AI Search** | Index management, queries, knowledge bases |
| 🎤 **Azure AI Services Speech** | Speech-to-text, text-to-speech |
| ⚙️ **Azure App Configuration** | Key-value store management |
| 🕸️ **Azure App Service** | Web app hosting and management |
| 🛡️ **Azure Best Practices** | Secure, production-grade guidance |
| 🖥️ **Azure CLI Generate** | Generate Azure CLI commands from natural language |
| 📞 **Azure Communication Services** | SMS and email messaging |
| 💻 **Azure Compute** | Virtual Machines and Scale Sets management |
| 🔐 **Azure Confidential Ledger** | Tamper-proof ledger operations |
| 📦 **Azure Container Apps** | Container hosting |
| 📦 **Azure Container Registry** | Container registry management |
| 📊 **Azure Cosmos DB** | NoSQL database operations |
| 🧮 **Azure Data Explorer** | Analytics queries and KQL |
| 🐬 **Azure Database for MySQL** | MySQL database management |
| 🐘 **Azure Database for PostgreSQL** | PostgreSQL database management |
| 📣 **Azure Event Grid** | Event routing and management |
| 📂 **Azure File Shares** | Managed file share operations |
| ⚡ **Azure Functions** | Function App management |
| 🔑 **Azure Key Vault** | Secrets, keys, and certificates |
| ☸️ **Azure Kubernetes Service** | Container orchestration |
| 📦 **Azure Load Testing** | Performance testing |
| 🚀 **Azure Managed Grafana** | Monitoring dashboards |
| 🗃️ **Azure Managed Lustre** | High-performance filesystem |
| 🏪 **Azure Marketplace** | Product discovery |
| 🔄 **Azure Migrate** | Platform Landing Zone guidance |
| 📈 **Azure Monitor** | Logging, metrics, health monitoring |
| ⚖️ **Azure Policy** | Organizational standards enforcement |
| ⚙️ **Azure Native ISV Services** | Third-party integrations |
| 🛡️ **Azure Quick Review CLI** | Compliance scanning |
| 📊 **Azure Quota** | Resource quota and usage |
| 🎭 **Azure RBAC** | Access control management |
| 🔴 **Azure Redis Cache** | In-memory data store |
| 🏗️ **Azure Resource Groups** | Resource organization |
| 🚌 **Azure Service Bus** | Message queuing |
| 🏥 **Azure Service Health** | Resource health and availability |
| 🗄️ **Azure SQL Database** | Relational database management |
| 🗄️ **Azure SQL Elastic Pool** | Database resource sharing |
| 🗄️ **Azure SQL Server** | Server administration |
| 💾 **Azure Storage** | Blob storage operations |
| 🔄 **Azure Storage Sync** | File Sync management |
| 📋 **Azure Subscription** | Subscription management |
| 🏗️ **Azure Terraform Best Practices** | IaC guidance |
| 🖥️ **Azure Virtual Desktop** | Virtual desktop infrastructure |
| 📊 **Azure Workbooks** | Custom visualizations |
| 🏗️ **Bicep** | Azure resource templates |
| 🏗️ **Cloud Architect** | Guided architecture design |

## Prerequisites

- **Power Platform license** (Copilot Studio + Power Apps)
- **Azure subscription** with **Owner** or **User Access Administrator** permissions
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)

## Quick Start

### 1. Deploy the Azure MCP Server

```bash
azd up
```

You will be prompted for:
- **Environment Name** — A name for managing this azd deployment
- **Azure Subscription** — The subscription to create resources in
- **Resource Group** — The resource group for the resources

### 2. Get Deployment Outputs

```bash
azd env get-values
```

Example output:
```
AZURE_RESOURCE_GROUP="<your_resource_group_name>"
AZURE_SUBSCRIPTION_ID="<your_subscription_id>"
AZURE_TENANT_ID="<your_tenant_id>"
CONTAINER_APP_NAME="azure-mcp-server"
CONTAINER_APP_URL="https://azure-mcp-server.<unique>.azurecontainerapps.io"
ENTRA_APP_CLIENT_CLIENT_ID="<client_app_id>"
ENTRA_APP_SERVER_CLIENT_ID="<server_app_id>"
```

### 3. Add API Permission to Client App

1. Go to **Azure Portal** → search for the client app using `ENTRA_APP_CLIENT_CLIENT_ID`
2. Navigate to **API permissions** blade
3. Click **Add a permission** → select the server app in **My APIs** tab
4. Add the `Mcp.Tools.ReadWrite` scope

### 4. Configure Custom Connector in Power Apps

Login to [Power Apps](https://make.powerapps.com) and create a custom connector:

#### General Tab
- Set **Scheme** to `HTTPS`
- Set **Host** to your `CONTAINER_APP_URL` value

#### Swagger Editor
Enter the swagger config (or import `custom-connector-swagger-example.yaml`):

```yaml
swagger: '2.0'
info:
  title: AzureMcpServer
  description: Connector to Azure MCP Server for all Azure operations
  version: '1.0'
host: <your_container_app_url>
basePath: /
schemes:
  - https
paths:
  /:
    post:
      summary: Azure MCP Server
      x-ms-agentic-protocol: mcp-streamable-1.0
      responses:
        '200':
          description: Success
      operationId: McpToolExecute
```

#### Security Tab
| Setting | Value |
|---------|-------|
| Authentication type | `OAuth 2.0` |
| Identity Provider | `Azure Active Directory` |
| Client ID | `ENTRA_APP_CLIENT_CLIENT_ID` |
| Secret options | `Use client secret` or `Use managed identity` |
| Authorization URL | `https://login.microsoftonline.com` |
| Tenant ID | `AZURE_TENANT_ID` |
| Resource URL | `ENTRA_APP_SERVER_CLIENT_ID` |
| Enable on-behalf-of login | `true` |
| Scope | `<server_app_client_id>/.default` |

#### Create & Configure
1. Click **Create connector**
2. Copy the **Redirect URL** from the connector
3. Go to Azure Portal → Client app registration → **Authentication** → Add the redirect URI
4. If using managed identity: Create **Federated Credentials** in the client app

#### Test Connection
1. Edit the custom connector → go to **Test** tab
2. Click **New connection** → sign in with your Azure account

### 5. Connect to Copilot Studio Agent

1. Open [Copilot Studio](https://copilotstudio.microsoft.com)
2. Create or select an Agent
3. Navigate to the **Tools** tab
4. Click **Add a tool** → search for your custom connector
5. After adding, the agent should list all available Azure MCP tools
6. Click **Test** and try prompts like:

#### Example Prompts

```
"List my Azure resource groups"
"Show all virtual machines in my subscription"
"List my Azure storage accounts"
"What secrets are in my key vault 'my-vault'?"
"List my Cosmos DB databases"
"Show me my AKS clusters"
"Query my Log Analytics workspace"
"List all SQL servers in my subscription"
"Show my App Configuration stores"
"List all Event Grid topics"
"Get my Key Vault certificates"
"List Redis Cache instances"
"Show my Azure Functions apps"
"List Service Bus namespaces"
"Create a new resource group in East US"
"Create a storage account named 'mystorageacct' in West US"
```

## What Gets Deployed

| Resource | Description |
|----------|-------------|
| **Container App** | Runs Azure MCP Server with ALL Azure tools enabled |
| **User-assigned Managed Identity** | Identity with Contributor role for Azure operations |
| **Entra App Registration (Server)** | OAuth 2.0 authentication with `Mcp.Tools.ReadWrite` scope |
| **Entra App Registration (Client)** | For Power Apps custom connector authentication |
| **Application Insights** | Telemetry and monitoring (optional, disabled by default) |

## Template Structure

```
├── azure.yaml                          # azd configuration
├── custom-connector-swagger-example.yaml # Swagger for Power Apps connector
├── infra/
│   ├── bicepconfig.json               # Bicep extensions config
│   ├── main.bicep                     # Main orchestration
│   ├── main.parameters.json           # Default parameters
│   └── modules/
│       ├── aca-infrastructure.bicep    # Container App (all tools, no read-only)
│       ├── aca-managed-identity.bicep  # User-assigned managed identity
│       ├── aca-subscription-role.bicep # Contributor role assignment
│       ├── application-insights.bicep  # App Insights (optional)
│       └── entra-app.bicep            # Entra App registrations
└── README.md
```

## Key Differences from Reference Template

This template extends the [Azure Samples reference](https://github.com/Azure-Samples/azmcp-copilot-studio-aca-mi) with the following changes:

| Aspect | Reference (Storage Only) | This Template (All Azure) |
|--------|-------------------------|--------------------------|
| **Namespaces** | `storage` only | All services (no filter) |
| **Access Mode** | Read-only (`--read-only`) | Full access (read + write) |
| **RBAC Role** | Reader | Contributor |
| **Container Resources** | 0.25 CPU / 0.5Gi | 0.5 CPU / 1Gi |
| **Tool Count** | ~10 storage tools | 200+ tools across 42+ services |

## Configuration Options

### Enable Read-Only Mode

To restrict the agent to read-only operations, add `'--read-only'` to the `serverArgs` in `infra/modules/aca-infrastructure.bicep`:

```bicep
var serverArgs = [
  '--transport'
  'http'
  '--outgoing-auth-strategy'
  'UseHostingEnvironmentIdentity'
  '--mode'
  'all'
  '--read-only'   // Add this line
]
```

### Filter to Specific Namespaces

To expose only specific Azure services, add `--namespace` args:

```bicep
var serverArgs = [
  '--transport'
  'http'
  '--outgoing-auth-strategy'
  'UseHostingEnvironmentIdentity'
  '--mode'
  'all'
  '--namespace'
  'storage'
  '--namespace'
  'keyvault'
  '--namespace'
  'compute'
]
```

### Enable Application Insights

Change `appInsightsConnectionString` in `main.parameters.json` from `"DISABLED"` to `""` to auto-create Application Insights:

```json
{
  "appInsightsConnectionString": {
    "value": ""
  }
}
```

## Security Considerations

> ⚠️ **Important:** This template deploys the Azure MCP Server with **Contributor** role and **all tools enabled** (including write/delete operations). Ensure that:
>
> - Only trusted agents and users can access the MCP server
> - Apply **least-privilege RBAC roles** appropriate for your use case
> - Consider enabling `--read-only` mode if write operations are not needed
> - Review [Azure MCP Server security documentation](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/README.md#security)

## Clean Up

```bash
azd down
```

> **Note:** `azd down` does not delete Entra app registrations. Manually delete them in Azure Portal using the `ENTRA_APP_CLIENT_CLIENT_ID` and `ENTRA_APP_SERVER_CLIENT_ID` values. Also clean up Power Platform resources (Copilot Studio Agent, custom connector, connection) via their respective UIs.

## References

- [Azure MCP Server Documentation](https://learn.microsoft.com/azure/developer/azure-mcp-server/)
- [Azure MCP Commands Reference](https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/docs/azmcp-commands.md)
- [Azure MCP Server GitHub](https://github.com/microsoft/mcp)
- [Copilot Studio MCP Integration](https://learn.microsoft.com/microsoft-copilot-studio/mcp-add-existing-server-to-agent)
- [Reference Template (Storage Only)](https://github.com/Azure-Samples/azmcp-copilot-studio-aca-mi)

## Known Issues

- Power Apps custom connector doesn't support multi-tenant authentication. The client app registration must be configured for single tenant only.
- Users or tenant admins must grant consent for the client app. See [application consent experience](https://learn.microsoft.com/entra/identity-platform/application-consent-experience) for options.
- If client and server app registrations are in different tenants, a tenant admin must provision a service principal: `az ad sp create --id <server_app_registration_client_id>`
- Power Platform tenant isolation policies may block cross-tenant data flow. See [cross-tenant restrictions](https://learn.microsoft.com/power-platform/admin/cross-tenant-restrictions) for exception rules.

## License

MIT
