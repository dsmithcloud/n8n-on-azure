# n8n on Azure Container Apps

This repository contains a Bicep template for deploying [n8n](https://n8n.io) workflow automation platform on Azure Container Apps with enterprise-grade security and monitoring.

## 🏗️ Architecture

The template deploys:

- **Azure Container Apps** - Serverless container hosting for n8n
- **Azure Key Vault** - Secure storage for encryption keys and secrets
- **Log Analytics Workspace** - Centralized logging and monitoring
- **Managed Identity** - Secure authentication between services

## 🔐 Security Features

- **Automatic encryption key generation** - Unique, secure keys generated per deployment
- **Azure Key Vault integration** - All secrets stored securely with RBAC
- **Managed Identity authentication** - No hardcoded credentials
- **Soft delete and purge protection** - Key Vault recovery capabilities
- **Role-based access control** - Principle of least privilege

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

All parameters have sensible defaults, but can be customized:

| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `containerAppName` | Name for the n8n container app | `n8n` | string |
| `workspaceName` | Log Analytics workspace name | `workspace-{uniqueString}` | string |
| `managedEnvironmentName` | Container Apps environment name | `managedEnvironment-{uniqueString}` | string |
| `location` | Azure region for deployment | Resource Group location | string |
| `logRetentionInDays` | Log retention period | `30` | int |
| `timezone` | Timezone for n8n container | `UTC` | string |
| `minReplicas` | Minimum container replicas | `0` | int |
| `maxReplicas` | Maximum container replicas | `10` | int |
| `cpuCores` | CPU allocation per container | `1` | string |
| `memorySize` | Memory allocation per container | `2Gi` | string |
| `keyVaultName` | Key Vault name | `kv-{uniqueString}` | string |
| `keyVaultSku` | Key Vault pricing tier | `standard` | string |

### Example with Custom Parameters

```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters \
    containerAppName="my-n8n" \
    timezone="America/New_York" \
    maxReplicas=5 \
    cpuCores="0.5" \
    memorySize="1Gi"
```

## 📊 Outputs

The template provides these outputs for integration with other systems:

- `containerAppFQDN` - Full URL to access n8n
- `containerAppName` - Name of the deployed container app
- `keyVaultName` - Name of the Key Vault storing secrets
- `keyVaultUri` - URI for Key Vault access
- `managedEnvironmentDefaultDomain` - Container Apps environment domain

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
- **Scale to zero** when not in use (cost optimization)
- **Automatic scaling** based on demand (0-10 replicas by default)
- **Configurable scaling parameters**

### Monitoring
- **Log Analytics integration** for centralized logging
- **Container app metrics** available in Azure Monitor
- **Configurable log retention** (30 days by default)

## 🔒 Security Considerations

### Key Vault Security
- RBAC authorization enabled
- Soft delete with 90-day retention
- Purge protection enabled
- System-assigned managed identity access only

### Container Security
- Official n8n Docker image
- No hardcoded secrets
- Secure environment variable injection
- Settings file permission enforcement

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
2. **App Won't Start**: Verify container resource allocation
3. **Key Vault Access Denied**: Ensure managed identity has proper permissions

### Viewing Logs

```bash
# View container logs
az containerapp logs show \
  --resource-group <your-resource-group> \
  --name <container-app-name>
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
