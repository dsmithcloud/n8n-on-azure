# n8n on Azure Container Apps

This repository contains an enterprise-grade Bicep template for deploying [n8n](https://n8n.io) workflow automation platform on Azure Container Apps with advanced security, networking, and monitoring capabilities.

## 🏗️ Architecture

The template supports three deployment modes with flexible networking options and follows Microsoft Cloud Adoption Framework (CAF) naming conventions:

### **Public Access (Default)**
- **Azure Container Apps** - Serverless container hosting for n8n
- **Azure Key Vault** - Secure storage for encryption keys and secrets
- **Log Analytics Workspace** - Centralized logging and monitoring
- **Managed Identity** - Secure authentication between services

### **VNet-Only Access**
- All of the above, plus:
- **Virtual Network** - Private network isolation with CAF-compliant naming
- **Internal Container Apps Environment** - No external endpoints
- **Subnet Delegation** - Dedicated subnets for Container Apps

### **VNet + External Access (Enterprise)**
- All of the above, plus:
- **Application Gateway WAF v2** - Web Application Firewall with OWASP 3.2 rules
- **Azure Front Door Premium** - Global CDN with advanced security and DDoS protection
- **Public IP** - Static IP for Application Gateway with DNS label

## 🎯 Features

### **Enterprise Security**
- 🔐 **Web Application Firewall (WAF v2)** - OWASP 3.2 ruleset in Prevention mode
- 🛡️ **Azure Front Door Premium** - Advanced threat protection and bot management
- 🔑 **Key Vault RBAC** - Role-based access control for secrets
- 🌐 **Network Isolation** - VNet integration with private endpoints
- 🚫 **DDoS Protection** - Enterprise-grade protection via Front Door Premium

### **Cloud Adoption Framework (CAF) Compliance**
- 📛 **Standardized Naming** - Consistent resource naming following Microsoft CAF standards
- 🏷️ **Comprehensive Tagging** - Cost center, owner, environment, and workload tracking
- 🌍 **Multi-Environment Support** - Dev, test, prod environment configurations
- 📍 **Location-Aware Naming** - Resources named with region and instance identifiers

### **Operational Excellence**
- 📊 **Auto-Scaling** - Scale to zero for cost optimization, scale up on demand
- 📈 **Comprehensive Monitoring** - Log Analytics integration with customizable retention
- 🔄 **High Availability** - Multi-region Front Door with health probes
- 💰 **Cost Optimization** - Consumption-based pricing with intelligent scaling

## 🚀 Quick Deploy

### **Default Public Deployment**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters location=eastus environment=prod
```

### **VNet-Only (Internal Access)**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters \
    location=eastus \
    environment=prod \
    enableVNetIntegration=true \
    enableExternalAccess=false
```

### **Enterprise VNet + External Access (Recommended for Production)**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters \
    location=eastus \
    environment=prod \
    enableVNetIntegration=true \
    enableExternalAccess=true \
    minReplicas=1
```

## 📝 CAF Naming Convention

The template follows Microsoft Cloud Adoption Framework naming standards:

### **Resource Naming Pattern**
```
<resource-type>-<application>-<workload>-<environment>-<location>-<instance>
```

### **Example Resource Names**
| Resource Type | Example Name |
|---------------|--------------|
| Container App | `ca-n8n-workflow-prod-eastus-001` |
| Log Analytics | `log-n8n-workflow-prod-eastus-001` |
| Container Environment | `cae-n8n-workflow-prod-eastus-001` |
| Key Vault | `kv-n8n-a1b2c3d4` (shortened due to 24-char limit) |
| Virtual Network | `vnet-n8n-workflow-prod-eastus-001` |
| Application Gateway | `agw-n8n-workflow-prod-eastus-001` |
| Front Door Profile | `afd-n8n-workflow-prod-eastus-001` |
| Public IP | `pip-agw-n8n-workflow-prod-eastus-001` |

### **Abbreviations Used**
- `ca` = Container App
- `log` = Log Analytics workspace
- `cae` = Container Apps Environment
- `kv` = Key Vault
- `vnet` = Virtual Network
- `snet` = Subnet
- `agw` = Application Gateway
- `afd` = Azure Front Door
- `pip` = Public IP address

## ⚙️ Configuration Parameters

### **Core Identity Parameters**
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `location` | Azure region for deployment | Resource Group location | string |
| `applicationName` | Application identifier | `n8n` | string |
| `environment` | Environment (dev, test, prod) | `prod` | string |
| `workloadName` | Workload identifier | `workflow` | string |
| `instance` | Instance number for multiple deployments | `001` | string |

### **Tagging Parameters**
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `tags` | Resource tags object | See template | object |

**Default Tags Applied:**
- `Environment` - Environment name (dev/test/prod)
- `Application` - Application name (n8n)
- `Workload` - Workload type (workflow)
- `CostCenter` - Cost tracking identifier
- `Owner` - Resource owner
- `CreatedBy` - Deployment method (Bicep)
- `DeploymentDate` - UTC deployment date

### **Container Configuration**
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
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
| `tenantId` | Azure AD tenant ID | Auto-detected | string |

## 💼 Enterprise Example Deployment

```bash
az deployment group create \
  --resource-group rg-n8n-production \
  --template-file main.bicep \
  --parameters \
    location="eastus" \
    environment="prod" \
    applicationName="n8n" \
    workloadName="automation" \
    instance="001" \
    enableVNetIntegration=true \
    enableExternalAccess=true \
    minReplicas=2 \
    maxReplicas=20 \
    cpuCores="2" \
    memorySize="4Gi" \
    logRetentionInDays=90 \
    tags='{
      "CostCenter": "IT-AUTOMATION-001",
      "Owner": "platform-team@company.com",
      "BusinessUnit": "Operations",
      "Environment": "prod"
    }'
```

## 📊 Outputs

The template provides comprehensive outputs for integration:

### **All Deployments**
- `containerAppFQDN` - Direct Container App URL
- `containerAppName` - CAF-compliant container app name
- `keyVaultName` - Key Vault name with secrets
- `keyVaultUri` - Key Vault URI for programmatic access
- `managedEnvironmentDefaultDomain` - Container Apps environment domain

### **VNet Deployments**
- `vnetId` - Virtual Network resource ID
- `vnetName` - CAF-compliant VNet name
- `isVNetIntegrated` - VNet integration status

### **External Access Deployments**
- `appGatewayFQDN` - Application Gateway WAF v2 public URL
- `frontDoorEndpointHostName` - Azure Front Door Premium endpoint URL
- `hasExternalAccess` - External access configuration status

## 🌐 Accessing n8n

### **Public Deployment**
```bash
# Get the Container Apps URL
az deployment group show \
  --resource-group <your-resource-group> \
  --name <deployment-name> \
  --query properties.outputs.containerAppFQDN.value -o tsv
```

### **Enterprise VNet + External Access (Recommended)**
```bash
# Get the Front Door Premium URL (global, with DDoS protection)
az deployment group show \
  --resource-group <your-resource-group> \
  --name <deployment-name> \
  --query properties.outputs.frontDoorEndpointHostName.value -o tsv

# Example output: https://n8n-ep-prod-a1b2c3d4.azurefd.net
```

### **VNet-Only (Internal Access)**
Access is available only from within the VNet using the internal FQDN. Ideal for secure, private deployments.

## 🔐 Security Features

### **Web Application Firewall (WAF v2)**
- **OWASP 3.2 Core Rule Set** - Industry-standard protection
- **Prevention Mode** - Actively blocks malicious traffic
- **Request Body Inspection** - Deep packet analysis
- **File Upload Protection** - Configurable upload limits
- **Custom Rule Support** - Add organization-specific rules

### **Azure Front Door Premium Security**
- **Advanced DDoS Protection** - Multi-layered threat protection
- **Bot Management** - Intelligent bot detection and mitigation
- **Rate Limiting** - Configurable request throttling
- **Geo-filtering** - Country/region-based access control
- **SSL/TLS Optimization** - Latest protocol support

### **Key Vault Integration**
- **RBAC Authorization** - Role-based access control
- **Soft Delete Protection** - 90-day recovery window
- **Purge Protection** - Prevents permanent deletion
- **Network ACLs** - IP-based access restrictions
- **Private Endpoints** - VNet-integrated access

### **Container Security**
- **Managed Identity** - No stored credentials
- **Official Images** - Latest n8n Docker images
- **Environment Variable Injection** - Secure secret management
- **Network Policies** - Micro-segmentation support

## 📈 Monitoring and Observability

### **Auto-Scaling**
- **Scale to Zero** - Cost optimization when idle
- **Event-Driven Scaling** - HTTP request-based scaling
- **Custom Metrics** - CPU, memory, and custom metric scaling
- **Configurable Thresholds** - Fine-tune scaling behavior

### **Monitoring Stack**
- **Log Analytics Integration** - Centralized log aggregation
- **Application Insights** - Optional APM integration
- **Azure Monitor Metrics** - Resource utilization tracking
- **Front Door Analytics** - Global traffic insights
- **WAF Metrics** - Security event monitoring

### **Alerting**
```bash
# Create sample alert for high CPU usage
az monitor metrics alert create \
  --name "n8n-high-cpu" \
  --resource-group <your-resource-group> \
  --scopes <container-app-resource-id> \
  --condition "avg UsageNanoCores > 800000000" \
  --description "n8n CPU usage above 80%"
```

## 💰 Cost Optimization

### **Estimated Monthly Costs**

| Deployment Mode | Basic Usage* | Production Usage* |
|-----------------|--------------|-------------------|
| **Public** | $15-40 | $50-150 |
| **VNet-Only** | $60-120 | $150-300 |
| **Enterprise (VNet + External)** | $250-500 | $600-1,200 |

*Costs vary by region, usage patterns, data transfer, and configuration

### **Cost Factors**
- **Container Apps** - Consumption-based pricing
- **Application Gateway WAF v2** - Fixed + data processing costs
- **Front Door Premium** - Request volume + data transfer
- **Key Vault** - Operations + stored secrets
- **Log Analytics** - Data ingestion + retention
- **VNet** - Minimal cost for private networking

### **Cost Optimization Tips**
1. **Use minReplicas=0** for development environments
2. **Configure appropriate log retention** periods
3. **Monitor Front Door data transfer** costs
4. **Use Azure Reservations** for predictable workloads
5. **Implement resource tagging** for cost allocation

## 🛠️ Advanced Configuration

### **Custom Environment Variables**
```bicep
// Add to container environment variables
{
  name: 'N8N_DEFAULT_BINARY_DATA_MODE'
  value: 'filesystem'
}
{
  name: 'N8N_BINARY_DATA_TTL'
  value: '24'
}
```

### **WAF Custom Rules**
```bash
# Add custom WAF rule
az network application-gateway waf-policy custom-rule create \
  --resource-group <your-resource-group> \
  --policy-name <waf-policy-name> \
  --name "BlockSQLInjection" \
  --priority 100 \
  --rule-type MatchRule \
  --action Block \
  --match-conditions '[{
    "matchVariables": [{"variableName": "QueryString"}],
    "operator": "Contains",
    "negationCondition": false,
    "matchValues": ["SELECT", "UNION", "DROP"]
  }]'
```

### **Front Door Custom Domains**
```bash
# Add custom domain to Front Door
az afd custom-domain create \
  --resource-group <your-resource-group> \
  --profile-name <front-door-profile> \
  --custom-domain-name "n8n-custom" \
  --host-name "workflows.yourdomain.com" \
  --certificate-type ManagedCertificate
```

### **Volume Mounts for Persistence**
```bicep
// Add to Container Apps template
volumes: [
  {
    name: 'n8n-data'
    storageType: 'AzureFile'
    storageName: 'n8n-storage-account'
  }
]
volumeMounts: [
  {
    volumeName: 'n8n-data'
    mountPath: '/home/node/.n8n'
  }
]
```

## 🔧 Troubleshooting

### **Common Issues and Solutions**

#### **Deployment Failures**
```bash
# Check deployment status
az deployment group show \
  --resource-group <your-resource-group> \
  --name <deployment-name>

# View deployment errors
az deployment operation group list \
  --resource-group <your-resource-group> \
  --name <deployment-name>
```

#### **Container App Issues**
```bash
# View container logs
az containerapp logs show \
  --resource-group <your-resource-group> \
  --name <ca-n8n-name> \
  --tail 50

# Check revision status
az containerapp revision list \
  --resource-group <your-resource-group> \
  --name <ca-n8n-name>
```

#### **WAF Blocking Legitimate Traffic**
```bash
# Check WAF logs
az monitor activity-log list \
  --resource-group <your-resource-group> \
  --resource-id <app-gateway-resource-id> \
  --start-time 2024-01-01T00:00:00Z

# Temporarily set WAF to Detection mode
az network application-gateway waf-config set \
  --resource-group <your-resource-group> \
  --gateway-name <app-gateway-name> \
  --enabled true \
  --firewall-mode Detection
```

#### **Front Door Health Issues**
```bash
# Check origin health
az afd origin show \
  --resource-group <your-resource-group> \
  --profile-name <front-door-profile> \
  --origin-group-name <origin-group-name> \
  --origin-name <origin-name>
```

#### **Network Connectivity**
```bash
# Test VNet configuration
az network vnet subnet show \
  --resource-group <your-resource-group> \
  --vnet-name <vnet-name> \
  --name <subnet-name>

# Check Container Apps environment
az containerapp env show \
  --resource-group <your-resource-group> \
  --name <cae-name>
```

## 🔄 Deployment Modes Comparison

| Feature | Public | VNet-Only | Enterprise |
|---------|---------|-----------|------------|
| **Internet Access** | Direct | None | Via Front Door Premium |
| **Private Access** | No | Yes | Yes |
| **WAF Protection** | No | No | WAF v2 with OWASP 3.2 |
| **DDoS Protection** | Basic | N/A | Premium |
| **SSL Termination** | Container Apps | N/A | Front Door + App Gateway |
| **Custom Domains** | Limited | Internal only | Full support with SSL |
| **Global Distribution** | Regional | N/A | Multi-region |
| **Bot Protection** | No | N/A | Advanced (Front Door Premium) |
| **Geo-filtering** | No | N/A | Yes |
| **Rate Limiting** | Basic | N/A | Advanced |
| **Cost** | Low | Medium | High |
| **Complexity** | Low | Medium | High |
| **Enterprise Ready** | No | Partial | Yes |

## 📋 Pre-deployment Checklist

- [ ] Azure subscription with sufficient permissions
- [ ] Resource group created or permissions to create
- [ ] Azure CLI or PowerShell installed and authenticated
- [ ] Bicep CLI available (or use Azure CLI with Bicep extension)
- [ ] Network requirements defined (if using VNet integration)
- [ ] Custom domain DNS access (if using custom domains)
- [ ] Cost budget approved for selected deployment mode
- [ ] Security requirements reviewed and approved
- [ ] Monitoring and alerting strategy defined

## 🚀 Getting Started Guide

### **Step 1: Environment Setup**
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <your-subscription-id>

# Create resource group
az group create --name rg-n8n-prod --location eastus
```

### **Step 2: Deploy Template**
```bash
# Basic deployment
az deployment group create \
  --resource-group rg-n8n-prod \
  --template-file main.bicep \
  --parameters environment=prod minReplicas=1

# Enterprise deployment
az deployment group create \
  --resource-group rg-n8n-prod \
  --template-file main.bicep \
  --parameters \
    environment=prod \
    enableVNetIntegration=true \
    enableExternalAccess=true \
    minReplicas=2
```

### **Step 3: Verify Deployment**
```bash
# Get n8n URL
URL=$(az deployment group show \
  --resource-group rg-n8n-prod \
  --name main \
  --query properties.outputs.containerAppFQDN.value -o tsv)

echo "n8n is available at: $URL"

# Test connectivity
curl -I $URL
```

### **Step 4: Configure n8n**
1. Navigate to the deployed URL
2. Complete n8n initial setup
3. Configure user accounts and security settings
4. Import or create your first workflows

## 🔒 Security Best Practices

### **Initial Security Configuration**
1. **Change default credentials** immediately after deployment
2. **Enable MFA** for all user accounts
3. **Configure RBAC** for team access
4. **Review WAF rules** and customize as needed
5. **Set up monitoring alerts** for security events
6. **Configure backup strategies** for workflows and data

### **Ongoing Security Maintenance**
- Regularly review access logs
- Update WAF rules based on threat intelligence
- Monitor Front Door analytics for anomalies
- Keep container images updated
- Review and rotate Key Vault secrets
- Audit user access and permissions

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes following CAF naming conventions
4. Test thoroughly in a development environment
5. Update documentation as needed
6. Submit a pull request

### **Development Guidelines**
- Follow Microsoft CAF naming standards
- Include comprehensive testing
- Update README for new features
- Maintain backward compatibility
- Add appropriate resource tags

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Azure Front Door Documentation](https://docs.microsoft.com/en-us/azure/frontdoor/)
- [Azure Application Gateway Documentation](https://docs.microsoft.com/en-us/azure/application-gateway/)
- [Microsoft Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)

---

**Built with ❤️ for the Azure community**

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

---

**Built with ❤️ for the Azure community**
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
