# n8n on Azure Container Apps

This repository contains a Bicep template for deploying [n8n](https://n8n.io) workflow automation platform on Azure Container Apps with enterprise-grade security, monitoring, and Cloud Adoption Framework (CAF) compliant naming.

**✨ Now using Azure Verified Modules (AVM)** - This template leverages Azure Verified Modules for enhanced reliability, security, and best practices compliance.

## 🏗️ Architecture

The template deploys using Azure Verified Modules (AVM) with CAF-compliant naming:

- **Azure Container Apps** - Serverless container hosting for n8n (via AVM)
- **Azure Key Vault** - Secure storage for encryption keys and secrets (via AVM)
- **Log Analytics Workspace** - Centralized logging and monitoring (via AVM)
- **User-Assigned Managed Identity** - Secure authentication with proper dependency management (via AVM)
- **Role-Based Access Control** - Automated RBAC assignments for secure service communication (via AVM)

## 🔐 Security Features

- **User-assigned managed identity** - Eliminates circular dependencies and improves security posture
- **Automatic encryption key generation** - Unique, secure keys generated per deployment
- **Azure Key Vault integration** - All secrets stored securely with RBAC
- **Proper dependency management** - Role assignments completed before container deployment
- **Soft delete and purge protection** - Key Vault recovery capabilities
- **Role-based access control** - Principle of least privilege with automated assignments
- **Azure Verified Modules** - Enterprise-grade security patterns and best practices
- **CAF naming conventions** - Consistent, enterprise-ready resource naming

## 🏷️ Cloud Adoption Framework (CAF) Naming

All resources follow Microsoft CAF naming conventions:

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| Container App | `ca-{workload}-{environment}-{location}-{uniqueId}` | `ca-n8n-dev-eus-abc123` |
| Key Vault | `kv-{workload}-{environment}-{location}-{uniqueId}` | `kv-n8n-dev-eus-abc123` |
| Log Analytics | `log-{workload}-{environment}-{location}-{uniqueId}` | `log-n8n-dev-eus-abc123` |
| Container Environment | `cae-{workload}-{environment}-{location}-{uniqueId}` | `cae-n8n-dev-eus-abc123` |
| Managed Identity | `id-{workload}-{environment}-{location}-{uniqueId}` | `id-n8n-dev-eus-abc123` |

## 📋 Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or Azure PowerShell
- Resource Group (or permissions to create one)

## 🚀 Quick Deploy

### Using Azure CLI

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep
```

### Using Azure PowerShell

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateFile "main.bicep"
```

## ⚙️ Configuration Parameters

All parameters have sensible defaults and follow CAF naming conventions:

| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `environment` | Environment name (dev, test, prod) | `dev` | string |
| `workloadName` | Workload name for the n8n deployment | `n8n` | string |
| `location` | Azure region for deployment | Resource Group location | string |
| `logRetentionInDays` | Log retention period | `30` | int |
| `timezone` | Timezone for n8n container | `UTC` | string |
| `minReplicas` | Minimum container replicas | `1` | int |
| `maxReplicas` | Maximum container replicas | `3` | int |
| `cpuCores` | CPU allocation per container | `1` | string |
| `memorySize` | Memory allocation per container | `2Gi` | string |
| `keyVaultSku` | Key Vault pricing tier | `standard` | string |
| `encryptionKeySeed` | Secure seed for encryption key generation | Auto-generated GUID | secure string |

### Example with Custom Parameters

```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters \
    environment="prod" \
    workloadName="workflow" \
    timezone="America/New_York" \
    maxReplicas=5 \
    cpuCores="0.5" \
    memorySize="1Gi"
```

## 📊 Outputs

The template provides these outputs for integration with other systems:

- `containerAppFQDN` - Full URL to access n8n
- `containerAppName` - CAF-compliant name of the deployed container app
- `keyVaultName` - CAF-compliant name of the Key Vault storing secrets
- `keyVaultUri` - URI for Key Vault access
- `workspaceName` - Log Analytics workspace name
- `managedEnvironmentName` - Container Apps environment name
- `managedEnvironmentDefaultDomain` - Container Apps environment domain
- `userAssignedManagedIdentityId` - Resource ID of the user-assigned managed identity
- `userAssignedManagedIdentityName` - Name of the user-assigned managed identity
- `userAssignedManagedIdentityPrincipalId` - Principal ID for RBAC assignments

## 🌐 Accessing n8n

After deployment, n8n will be available at the URL provided in the `containerAppFQDN` output:

```bash
# Get the URL from deployment output
az deployment group show \
  --resource-group <your-resource-group> \
  --name <deployment-name> \
  --query properties.outputs.containerAppFQDN.value
```

## 🔧 Environment Variables

The template automatically configures these n8n environment variables:

- `N8N_ENCRYPTION_KEY` - Secure key from Key Vault
- `GENERIC_TIMEZONE` - Configurable timezone
- `WEBHOOK_URL` - Auto-generated webhook endpoint
- `TRUST_PROXY` - Enabled for Azure Container Apps
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` - Security hardening

## 📈 Monitoring and Scaling

### Auto-scaling
- **Minimum replicas** set to 1 for production readiness (no cold starts)
- **Automatic scaling** based on demand (1-3 replicas by default)
- **Configurable scaling parameters** for different environments

### Monitoring
- **Log Analytics integration** for centralized logging
- **Container app metrics** available in Azure Monitor
- **Configurable log retention** (30 days by default)
- **User-assigned managed identity monitoring** for security auditing

## 🔒 Security Considerations

### Enhanced Security Model
- **User-assigned managed identity** eliminates circular dependencies
- **Automated role assignments** using Azure Verified Modules
- **Resource-scoped permissions** following principle of least privilege
- **Proper deployment sequencing** ensures security before app deployment

### Key Vault Security
- **RBAC authorization** enabled by default
- **Soft delete** with 90-day retention
- **Purge protection** enabled for production safety
- **User-assigned managed identity** access with specific role assignments

### Container Security
- **Official n8n Docker image** from Docker Hub
- **No hardcoded secrets** - all secrets from Key Vault
- **Secure environment variable injection** via managed identity
- **Settings file permission enforcement** for additional security

### Architecture Security Benefits
- **Eliminates circular dependencies** between managed identity and resource access
- **Explicit dependency management** ensures proper deployment order
- **Resource-specific role assignments** limit access scope
- **CAF naming conventions** improve security governance and compliance

## 🛠️ Customization

### Adding Custom Environment Variables

To add custom environment variables, modify the `env` array in the container configuration:

```bicep
env: [
  // ... existing variables
  {
    name: 'CUSTOM_VARIABLE'
    value: 'custom-value'
  }
]
```

### Persistent Storage

For persistent workflows and data, consider adding volume mounts:

```bicep
volumes: [
  {
    name: 'n8n-data'
    storageType: 'AzureFile'
    storageName: 'n8n-storage'
  }
]
```

## 🐛 Troubleshooting

### Common Issues

1. **Deployment Fails**: Check resource group permissions and quotas
2. **App Won't Start**: Verify container resource allocation and managed identity permissions
3. **Key Vault Access Denied**: Ensure user-assigned managed identity has proper role assignments
4. **Circular Dependency Errors**: This template resolves circular dependencies using user-assigned managed identity
5. **Container App Stuck in 'Activating'**: Check managed identity permissions and Key Vault access

### Deployment Sequence Verification

The template deploys resources in this order to avoid dependency issues:
1. User-Assigned Managed Identity
2. Log Analytics Workspace and Key Vault (parallel)
3. Role Assignment (MI → Key Vault permissions)
4. Container Apps Environment
5. Container App (with dependency on role assignment)

### Viewing Logs

```bash
# View container logs
az containerapp logs show \
  --resource-group <your-resource-group> \
  --name <container-app-name>

# Check managed identity permissions
az role assignment list \
  --assignee <managed-identity-principal-id> \
  --resource-group <your-resource-group>
```

### Debugging Managed Identity Issues

```bash
# Get managed identity details
az identity show \
  --resource-group <your-resource-group> \
  --name <managed-identity-name>

# Verify Key Vault access
az keyvault secret show \
  --vault-name <key-vault-name> \
  --name n8n-encryption-key
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
