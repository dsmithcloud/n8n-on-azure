# n8n on Azure Container Apps

This repository contains a Bicep template for deploying [n8n](https://n8n.io) workflow automation platform on Azure Container Apps with enterprise-grade security, networking, and monitoring capabilities.

## 🏗️ Architecture

The template supports three deployment modes with flexible networking options:

### **Public Access (Default)**
- **Azure Container Apps** - Serverless container hosting for n8n
- **Azure Key Vault** - Secure storage for encryption keys and secrets
- **Log Analytics Workspace** - Centralized logging and monitoring
- **Managed Identity** - Secure authentication between services

### **VNet-Only Access**
- All of the above, plus:
- **Virtual Network** - Private network isolation
- **Internal Container Apps Environment** - No external endpoints

### **VNet + External Access**
- All of the above, plus:
- **Application Gateway v2** - Load balancer with SSL termination
- **Azure Front Door** - Global CDN with DDoS protection
- **Public IP** - For Application Gateway

## 🚀 Quick Deploy

### **Default Public Deployment**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep
```

### **VNet-Only (Internal Access)**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters enableVNetIntegration=true enableExternalAccess=false
```

### **VNet + External Access (Recommended for Production)**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters enableVNetIntegration=true enableExternalAccess=true
```

## 🔐 Security Features

- **Automatic encryption key generation** - Unique, secure keys generated per deployment
- **Azure Key Vault integration** - All secrets stored securely with RBAC
- **Managed Identity authentication** - No hardcoded credentials
- **Soft delete and purge protection** - Key Vault recovery capabilities
- **Role-based access control** - Principle of least privilege
- **Network isolation** - VNet integration with private endpoints
- **DDoS protection** - Azure Front Door standard protection
- **SSL/TLS termination** - Secure communications at multiple layers

## � Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or Azure PowerShell
- Resource Group (or permissions to create one)

## ⚙️ Configuration Parameters

### **Core Parameters**
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `containerAppName` | Name for the n8n container app | `n8n` | string |
| `location` | Azure region for deployment | Resource Group location | string |
| `timezone` | Timezone for n8n container | `UTC` | string |
| `cpuCores` | CPU allocation per container | `1` | string |
| `memorySize` | Memory allocation per container | `2Gi` | string |
| `minReplicas` | Minimum container replicas | `0` | int |
| `maxReplicas` | Maximum container replicas | `10` | int |

### **Networking Parameters**
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `enableVNetIntegration` | Enable VNet isolation | `false` | bool |
| `enableExternalAccess` | Add App Gateway + Front Door | `true` | bool |
| `vnetAddressPrefix` | Virtual network address space | `10.0.0.0/16` | string |
| `containerAppsSubnetPrefix` | Container Apps subnet | `10.0.0.0/23` | string |
| `appGatewaySubnetPrefix` | Application Gateway subnet | `10.0.2.0/24` | string |

### **Security Parameters**
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `keyVaultSku` | Key Vault pricing tier | `standard` | string |
| `logRetentionInDays` | Log retention period | `30` | int |

### **Advanced Example with Custom Parameters**

```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters \
    containerAppName="my-n8n" \
    timezone="America/New_York" \
    enableVNetIntegration=true \
    enableExternalAccess=true \
    vnetAddressPrefix="192.168.0.0/16" \
    maxReplicas=5 \
    cpuCores="0.5" \
    memorySize="1Gi"
```

## 📊 Outputs

The template provides these outputs for integration with other systems:

### **All Deployments**
- `containerAppFQDN` - Direct Container App URL
- `containerAppName` - Name of the deployed container app
- `keyVaultName` - Name of the Key Vault storing secrets
- `keyVaultUri` - URI for Key Vault access
- `managedEnvironmentDefaultDomain` - Container Apps environment domain

### **VNet Deployments**
- `vnetId` - Virtual Network resource ID
- `vnetName` - Virtual Network name
- `isVNetIntegrated` - Boolean indicating VNet integration status

### **External Access Deployments**
- `appGatewayFQDN` - Application Gateway public URL
- `frontDoorEndpointHostName` - Azure Front Door endpoint URL
- `hasExternalAccess` - Boolean indicating external access configuration

## 🌐 Accessing n8n

### **Public Deployment**
```bash
# Get the URL from deployment output
az deployment group show \
  --resource-group <your-resource-group> \
  --name <deployment-name> \
  --query properties.outputs.containerAppFQDN.value
```

### **VNet + External Access**
```bash
# Get the Front Door URL (recommended)
az deployment group show \
  --resource-group <your-resource-group> \
  --name <deployment-name> \
  --query properties.outputs.frontDoorEndpointHostName.value
```

### **VNet-Only (Internal Access)**
Access is available only from within the VNet using the internal FQDN.

## 🔧 Environment Variables

The template automatically configures these n8n environment variables:

- `N8N_ENCRYPTION_KEY` - Secure key from Key Vault (auto-generated)
- `GENERIC_TIMEZONE` - Configurable timezone
- `WEBHOOK_URL` - Auto-generated webhook endpoint (varies by deployment mode)
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
- **Application Gateway metrics** (when enabled)
- **Front Door analytics** (when enabled)
- **Configurable log retention** (30 days by default)

## 🔒 Security Considerations

### **Key Vault Security**
- RBAC authorization enabled
- Soft delete with 90-day retention
- Purge protection enabled
- System-assigned managed identity access only

### **Container Security**
- Official n8n Docker image
- No hardcoded secrets
- Secure environment variable injection
- Settings file permission enforcement

### **Network Security**
- Optional VNet isolation
- Application Gateway WAF capabilities
- Azure Front Door DDoS protection
- Private endpoint support

## 💰 Cost Considerations

| Deployment Mode | Estimated Monthly Cost* |
|-----------------|------------------------|
| **Public** | $10-30 (Container Apps + Key Vault) |
| **VNet-Only** | $40-80 (+ VNet, Private DNS) |
| **VNet + External** | $200-400 (+ App Gateway + Front Door) |

*Costs vary by region, usage, and configuration

## 🛠️ Advanced Customization

### **Adding Custom Environment Variables**

```bicep
env: [
  // ... existing variables
  {
    name: 'CUSTOM_VARIABLE'
    value: 'custom-value'
  }
]
```

### **Enabling Web Application Firewall (WAF)**

For VNet + External deployments, you can enable WAF on Application Gateway:

```bash
az network application-gateway waf-config set \
  --resource-group <your-resource-group> \
  --gateway-name <app-gateway-name> \
  --enabled true \
  --firewall-mode Prevention
```

### **Adding Custom Domains**

Configure custom domains on Azure Front Door:

```bash
az afd custom-domain create \
  --resource-group <your-resource-group> \
  --profile-name <front-door-profile> \
  --custom-domain-name "n8n-custom" \
  --host-name "n8n.yourdomain.com"
```

### **Persistent Storage**

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

### **Common Issues**

1. **Deployment Fails**: Check resource group permissions and quotas
2. **App Won't Start**: Verify container resource allocation
3. **Key Vault Access Denied**: Ensure managed identity has proper permissions
4. **VNet Connectivity Issues**: Verify subnet delegations and NSG rules
5. **Application Gateway Health Issues**: Check backend pool configuration

### **Viewing Logs**

```bash
# View container logs
az containerapp logs show \
  --resource-group <your-resource-group> \
  --name <container-app-name>

# View Application Gateway logs (if enabled)
az monitor activity-log list \
  --resource-group <your-resource-group> \
  --resource-id <app-gateway-resource-id>
```

### **Network Diagnostics**

```bash
# Test VNet connectivity
az network vnet list --resource-group <your-resource-group>

# Check Container Apps environment status
az containerapp env show \
  --resource-group <your-resource-group> \
  --name <environment-name>
```

## 🔄 Deployment Modes Comparison

| Feature | Public | VNet-Only | VNet + External |
|---------|---------|-----------|-----------------|
| **Internet Access** | Direct | None | Via Front Door |
| **Private Access** | No | Yes | Yes |
| **DDoS Protection** | Basic | N/A | Advanced |
| **SSL Termination** | Container Apps | N/A | Front Door + App Gateway |
| **Custom Domains** | Limited | Internal only | Full support |
| **WAF Support** | No | N/A | Yes |
| **Global Distribution** | Regional | N/A | Yes |
| **Cost** | Low | Medium | High |
| **Complexity** | Low | Medium | High |

## 🚀 Next Steps

1. **Deploy with your preferred networking mode**
2. **Configure custom domains** (for external access)
3. **Set up monitoring alerts** in Azure Monitor
4. **Enable WAF policies** for additional security
5. **Configure backup strategies** for persistent data
6. **Set up CI/CD pipelines** for automated deployments

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
