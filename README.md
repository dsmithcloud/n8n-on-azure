# n8n on Azure Container Apps with Application Gateway v2

This repository contains a comprehensive Bicep template for deploying [n8n](https://n8n.io) workflow automation platform on Azure Container Apps with enterprise-grade security, networking, and Cloud Adoption Framework (CAF) compliant naming.

**✨ Now using Azure Verified Modules (AVM)** - This template leverages Azure Verified Modules for enhanced reliability, security, and best practices compliance.

## 🏗️ Architecture

The template deploys a comprehensive enterprise solution using Azure Verified Modules (AVM) with CAF-compliant naming:

### Core Infrastructure
- **Azure Container Apps (Internal)** - Serverless container hosting for n8n with VNet integration (via AVM)
- **Application Gateway v2** - Enterprise load balancer with TLS termination, WAF protection, and health monitoring
- **Web Application Firewall (WAF)** - OWASP 3.2 rules with Microsoft Bot Manager protection (via AVM)
- **Virtual Network** - Secure network with 4 dedicated subnets and Network Security Groups (via AVM)
- **Private DNS Zone** - Internal DNS resolution for Container Apps (via AVM)

### Security & Identity
- **Azure Key Vault** - Secure storage for TLS certificates and encryption keys (via AVM)
- **User-Assigned Managed Identity** - Secure authentication with proper dependency management (via AVM)
- **Role-Based Access Control** - Automated RBAC assignments for secure service communication (via AVM)

### Monitoring & Operations
- **Log Analytics Workspace** - Centralized logging and monitoring (via AVM)
- **Public IP Address** - Static IP for Application Gateway (via AVM)

## 🌐 Network Architecture

### VNet Configuration
- **Address Space**: `10.0.0.0/25` (128 IPs)
- **Subnet Layout** (each `/27` = 32 IPs):
  - **Default Subnet** (`10.0.0.0/27`) - General purpose with dedicated NSG
  - **Application Gateway Subnet** (`10.0.0.32/27`) - Dedicated for Application Gateway
  - **Container Apps Subnet** (`10.0.0.64/27`) - Internal Container Apps environment
  - **Extra Subnet** (`10.0.0.96/27`) - Reserved for future expansion

### Security Groups
- **Dedicated NSGs** for each subnet with appropriate security rules
- **Application Gateway NSG** - Allows HTTP/HTTPS traffic and Azure infrastructure
- **Container Apps NSG** - Allows internal traffic from Application Gateway subnet

## 🔐 Security Features

### Application Gateway Security
- **TLS Termination** - SSL/TLS certificates managed via Azure Key Vault integration
- **Web Application Firewall (WAF)** - OWASP 3.2 rules with Prevention mode enabled
- **Microsoft Bot Manager Rule Set** - Advanced bot protection and traffic filtering
- **HTTP to HTTPS Redirect** - Automatic enforcement of encrypted connections
- **Custom Health Probes** - Monitoring `/healthz` and `/healthz/readiness` endpoints

### Network Security
- **Internal Container Apps** - No public internet access, only via Application Gateway
- **Private DNS Integration** - Secure internal name resolution for Container Apps
- **Network Security Groups** - Granular traffic control for each subnet
- **VNet Integration** - Complete network isolation and segmentation

### Identity & Access Management
- **User-assigned managed identity** - Eliminates circular dependencies and improves security posture
- **Automatic encryption key generation** - Unique, secure keys generated per deployment
- **Azure Key Vault integration** - All secrets and certificates stored securely with RBAC
- **Proper dependency management** - Role assignments completed before container deployment
- **Soft delete and purge protection** - Key Vault recovery capabilities
- **Role-based access control** - Principle of least privilege with automated assignments

### Enterprise Compliance
- **Azure Verified Modules** - Enterprise-grade security patterns and best practices
- **CAF naming conventions** - Consistent, enterprise-ready resource naming
- **Comprehensive logging** - All components integrated with Log Analytics

## 🏷️ Cloud Adoption Framework (CAF) Naming

All resources follow Microsoft CAF naming conventions:

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| Application Gateway | `agw-{workload}-{environment}-{location}-{uniqueId}` | `agw-n8n-dev-scus-abc123` |
| WAF Policy | `wafpol-{workload}-{environment}-{location}-{uniqueId}` | `wafpol-n8n-dev-scus-abc123` |
| Virtual Network | `vnet-{workload}-{environment}-{location}-{uniqueId}` | `vnet-n8n-dev-scus-abc123` |
| Network Security Group | `nsg-{subnet}-{workload}-{environment}-{location}-{uniqueId}` | `nsg-appgw-n8n-dev-scus-abc123` |
| Public IP | `pip-{workload}-{environment}-{location}-{uniqueId}` | `pip-n8n-dev-scus-abc123` |
| Private DNS Zone | `privatelink.{region}.azurecontainerapps.io` | `privatelink.southcentralus.azurecontainerapps.io` |
| Container App | `ca-{workload}-{environment}-{location}-{uniqueId}` | `ca-n8n-dev-scus-abc123` |
| Container Environment | `cae-{workload}-{environment}-{location}-{uniqueId}` | `cae-n8n-dev-scus-abc123` |
| Key Vault | `kv-{workload}-{environment}-{location}-{uniqueId}` | `kv-n8n-dev-scus-abc123` |
| Log Analytics | `log-{workload}-{environment}-{location}-{uniqueId}` | `log-n8n-dev-scus-abc123` |
| Managed Identity | `id-{workload}-{environment}-{location}-{uniqueId}` | `id-n8n-dev-scus-abc123` |

## 📋 Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI or Azure PowerShell
- Resource Group (or permissions to create one)
- **TLS Certificate** - SSL certificate stored in Azure Key Vault for HTTPS termination
- **Custom Domain** - Domain name configured to point to Application Gateway public IP

## 🚀 Quick Deploy

### 1. Prepare TLS Certificate

First, upload your TLS certificate to Key Vault:

```bash
# Upload certificate to Key Vault
az keyvault certificate import \
  --vault-name <your-key-vault> \
  --name <certificate-name> \
  --file <certificate-file.pfx>
```

### 2. Deploy Infrastructure

#### Using Azure CLI

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters \
    workloadName=n8n \
    environment=dev \
    location=southcentralus \
    kvCertSecretId="https://<key-vault-name>.vault.azure.net/secrets/<cert-name>/<version>" \
    listenerHostNames='["yourdomain.com"]'
```

#### Using Azure PowerShell

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "<your-resource-group>" `
  -TemplateFile "main.bicep" `
  -workloadName "n8n" `
  -environment "dev" `
  -location "southcentralus" `
  -kvCertSecretId "https://<key-vault-name>.vault.azure.net/secrets/<cert-name>/<version>" `
  -listenerHostNames @("yourdomain.com")
```

## ⚙️ Configuration Parameters

### Required Parameters
| Parameter | Description | Type | Example |
|-----------|-------------|------|---------|
| `kvCertSecretId` | Key Vault secret ID for TLS certificate | secure string | `https://kv-....vault.azure.net/secrets/cert/version` |

### Core Configuration
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `workloadName` | Workload name for the n8n deployment | `n8n` | string |
| `environment` | Environment name (dev, test, prod) | `dev` | string |
| `location` | Azure region for deployment | Resource Group location | string |

### Application Gateway Parameters
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `appGatewayName` | Custom Application Gateway name (optional) | Auto-generated CAF name | string |
| `skuName` | Application Gateway SKU | `WAF_v2` | string |
| `listenerHostNames` | Host names for HTTPS listener | `['n8n.smithdavid.pro']` | array |
| `enableWaf` | Enable Web Application Firewall | `true` | bool |
| `enableHttpRedirect` | Enable HTTP to HTTPS redirect | `true` | bool |
| `autoscaleMin` | Minimum Application Gateway instances | `1` | int |
| `autoscaleMax` | Maximum Application Gateway instances | `5` | int |

### Backend Configuration
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `backendPort` | Backend port for Container App | `443` | int |
| `backendUseHttps` | Use HTTPS for backend communication | `true` | bool |
| `backendHostName` | Custom backend hostname | Auto-generated from Container App | string |
| `requestTimeoutSeconds` | Backend request timeout | `240` | int |
| `acaBackendFqdn` | Custom backend FQDN (optional) | Auto-generated | string |
| `acaBackendIpAddresses` | Backend IP addresses (optional) | `[]` | array |

### Container App Parameters
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `minReplicas` | Minimum container replicas | `1` | int |
| `maxReplicas` | Maximum container replicas | `3` | int |
| `cpuCores` | CPU allocation per container | `1` | string |
| `memorySize` | Memory allocation per container | `2Gi` | string |
| `timezone` | Timezone for n8n container | `UTC` | string |

### Security & Monitoring
| Parameter | Description | Default Value | Type |
|-----------|-------------|---------------|------|
| `keyVaultSku` | Key Vault pricing tier | `standard` | string |
| `logRetentionInDays` | Log retention period | `30` | int |
| `encryptionKeySeed` | Secure seed for encryption key generation | Auto-generated GUID | secure string |

### Example with Custom Parameters

```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters \
    workloadName="workflow" \
    environment="prod" \
    location="eastus2" \
    kvCertSecretId="https://kv-prod.vault.azure.net/secrets/ssl-cert/latest" \
    listenerHostNames='["workflow.contoso.com","www.workflow.contoso.com"]' \
    skuName="Standard_v2" \
    enableWaf="false" \
    autoscaleMax="10" \
    timezone="America/New_York" \
    maxReplicas="5" \
    cpuCores="0.5" \
    memorySize="1Gi"
```

## 📊 Outputs

The template provides these outputs for integration with other systems:

### Application Gateway Outputs
- `applicationGatewayFQDN` - Public FQDN of the Application Gateway
- `applicationGatewayPublicIP` - Public IP address of the Application Gateway
- `applicationGatewayName` - Name of the deployed Application Gateway

### Container App Outputs
- `containerAppFQDN` - Internal FQDN of the Container App (private)
- `containerAppName` - CAF-compliant name of the deployed Container App
- `managedEnvironmentName` - Container Apps environment name
- `managedEnvironmentDefaultDomain` - Container Apps environment domain

### Security & Identity Outputs
- `keyVaultName` - CAF-compliant name of the Key Vault storing secrets
- `keyVaultUri` - URI for Key Vault access
- `userAssignedManagedIdentityId` - Resource ID of the user-assigned managed identity
- `userAssignedManagedIdentityName` - Name of the user-assigned managed identity
- `userAssignedManagedIdentityPrincipalId` - Principal ID for RBAC assignments

### Networking Outputs
- `virtualNetworkName` - Name of the deployed Virtual Network
- `virtualNetworkId` - Resource ID of the Virtual Network
- `privateDnsZoneName` - Name of the Private DNS Zone

### Monitoring Outputs
- `workspaceName` - Log Analytics workspace name
- `workspaceId` - Log Analytics workspace resource ID

## 🌐 Accessing n8n

After deployment, n8n will be available via the Application Gateway at your custom domain:

```bash
# Get the Application Gateway public IP
az deployment group show \
  --resource-group <your-resource-group> \
  --name <deployment-name> \
  --query properties.outputs.applicationGatewayPublicIP.value

# Access n8n via your custom domain
curl https://yourdomain.com
```

### DNS Configuration

Point your custom domain to the Application Gateway public IP:
1. Get the public IP from the deployment outputs
2. Create an A record: `yourdomain.com → <Application-Gateway-Public-IP>`
3. Access n8n at `https://yourdomain.com`

## 🔧 Environment Variables

The template automatically configures these n8n environment variables:

- `N8N_ENCRYPTION_KEY` - Secure key from Key Vault
- `GENERIC_TIMEZONE` - Configurable timezone
- `WEBHOOK_URL` - Auto-generated webhook endpoint
- `TRUST_PROXY` - Enabled for Azure Container Apps
- `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` - Security hardening

## 📈 Monitoring and Scaling

### Application Gateway Auto-scaling
- **Minimum instances** configurable (default: 1)
- **Maximum instances** configurable (default: 5) 
- **Automatic scaling** based on CPU, memory, and connection metrics
- **Enterprise-grade availability** with multiple instances

### Container App Auto-scaling  
- **Minimum replicas** set to 1 for production readiness (no cold starts)
- **Automatic scaling** based on demand (1-3 replicas by default)
- **Configurable scaling parameters** for different environments
- **VNet-integrated** for secure communication

### Health Monitoring
- **Application Gateway Health Probes**:
  - Primary: `/healthz/readiness` (HTTPS)
  - Secondary: `/healthz` (HTTP)
- **Backend Health Monitoring** with configurable thresholds
- **Automatic failover** and traffic routing based on health status

### Monitoring & Observability
- **Log Analytics integration** for centralized logging
- **Application Gateway metrics** available in Azure Monitor
- **Container app metrics** and performance monitoring
- **WAF logs and security events** for threat analysis
- **Configurable log retention** (30 days by default)
- **User-assigned managed identity monitoring** for security auditing

### Performance Optimization
- **HTTP/2 enabled** on Application Gateway for better performance
- **Connection multiplexing** and **persistent connections**
- **Configurable request timeout** (240 seconds default)
- **Cookie-based affinity** disabled for stateless scaling

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

### Application Gateway Customization

#### Custom Backend Configuration
```bicep
// Use specific backend IP addresses instead of FQDN
param acaBackendIpAddresses array = ['10.0.0.100', '10.0.0.101']
param backendHostName string = 'n8n.internal.local'
```

#### Custom WAF Rules
```bicep
// Add custom WAF exclusions or rules
param enableWaf bool = true
// WAF policy is deployed via AVM with standard OWASP rules
```

#### Multi-domain Support
```bicep
param listenerHostNames array = [
  'n8n.contoso.com'
  'workflow.contoso.com' 
  'automation.contoso.com'
]
```

### Container App Customization

#### Adding Custom Environment Variables
```bicep
env: [
  // ... existing variables
  {
    name: 'CUSTOM_VARIABLE'
    value: 'custom-value'
  }
  {
    name: 'WEBHOOK_URL' 
    value: 'https://yourdomain.com'
  }
]
```

#### Custom Resource Allocation
```bicep
param cpuCores string = '2'
param memorySize string = '4Gi'
param maxReplicas int = 10
```

### Network Customization

#### Custom VNet Address Space
```bicep
// Modify the VNet address space in the template
var vnetAddressSpace = '172.16.0.0/24'
```

#### Additional Subnets
```bicep
// Add more subnets for additional services
subnets: [
  // ... existing subnets
  {
    name: 'database-subnet'
    addressPrefix: '10.0.0.128/27'
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

#### Application Gateway Issues
1. **502 Bad Gateway**: Check backend health probes and Container App status
2. **Certificate Issues**: Verify Key Vault certificate and managed identity permissions
3. **WAF Blocking Traffic**: Review WAF logs and adjust rules if needed
4. **DNS Resolution**: Ensure custom domain points to Application Gateway public IP

#### Container App Issues  
1. **App Won't Start**: Verify container resource allocation and managed identity permissions
2. **Container App Stuck in 'Activating'**: Check managed identity permissions and Key Vault access
3. **Health Probe Failures**: Verify `/healthz` and `/healthz/readiness` endpoints respond correctly

#### Network Connectivity Issues
1. **Private DNS Issues**: Verify Private DNS zone configuration and VNet links
2. **NSG Blocking Traffic**: Check Network Security Group rules for each subnet
3. **Subnet Connectivity**: Ensure Application Gateway can reach Container Apps subnet

#### Deployment Issues
1. **Deployment Fails**: Check resource group permissions and quotas
2. **Key Vault Access Denied**: Ensure user-assigned managed identity has proper role assignments
3. **Circular Dependency Errors**: This template resolves circular dependencies using user-assigned managed identity

### Deployment Sequence Verification

The template deploys resources in this order to avoid dependency issues:
1. **Network Infrastructure**: VNet, NSGs, Public IP
2. **User-Assigned Managed Identity**
3. **Log Analytics Workspace and Key Vault** (parallel)
4. **Role Assignment** (MI → Key Vault permissions)
5. **Private DNS Zone and WAF Policy** (parallel)
6. **Container Apps Environment** (with VNet integration)
7. **Container App** (with dependency on role assignment)
8. **Application Gateway** (with TLS certificate and health probes)

### Diagnostic Commands

#### Application Gateway Diagnostics
```bash
# Check Application Gateway backend health
az network application-gateway show-backend-health \
  --resource-group <your-resource-group> \
  --name <app-gateway-name>

# View Application Gateway configuration
az network application-gateway show \
  --resource-group <your-resource-group> \
  --name <app-gateway-name>

# Check WAF logs
az monitor log-analytics query \
  --workspace <log-analytics-workspace-id> \
  --analytics-query "AzureDiagnostics | where Category == 'ApplicationGatewayFirewallLog'"
```

#### Container App Diagnostics
```bash
# View container logs
az containerapp logs show \
  --resource-group <your-resource-group> \
  --name <container-app-name>

# Check container app status
az containerapp show \
  --resource-group <your-resource-group> \
  --name <container-app-name> \
  --query "properties.runningStatus"
```

#### Network Diagnostics
```bash
# Test private DNS resolution
az network private-dns record-set list \
  --resource-group <your-resource-group> \
  --zone-name <private-dns-zone>

# Check NSG effective rules
az network nsg show \
  --resource-group <your-resource-group> \
  --name <nsg-name>
```

### Health Probe Testing

Test health endpoints directly:
```bash
# Test from within VNet (if you have access)
curl -k https://<container-app-internal-fqdn>/healthz
curl -k https://<container-app-internal-fqdn>/healthz/readiness

# Check Application Gateway health probe status
az network application-gateway show-backend-health \
  --resource-group <your-resource-group> \
  --name <app-gateway-name> \
  --query "backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health"
```

### Debugging Managed Identity Issues

```bash
# Get managed identity details
az identity show \
  --resource-group <your-resource-group> \
  --name <managed-identity-name>

# Check managed identity permissions
az role assignment list \
  --assignee <managed-identity-principal-id> \
  --resource-group <your-resource-group>

# Verify Key Vault access
az keyvault secret show \
  --vault-name <key-vault-name> \
  --name n8n-encryption-key

# Test certificate access
az keyvault certificate show \
  --vault-name <key-vault-name> \
  --name <certificate-name>
```

### Performance Monitoring

```bash
# View Application Gateway metrics
az monitor metrics list \
  --resource <app-gateway-resource-id> \
  --metric "ResponseStatus,Throughput,BackendResponseStatus"

# Check Container App scaling metrics  
az monitor metrics list \
  --resource <container-app-resource-id> \
  --metric "Replicas,CpuPercentage,MemoryPercentage"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
