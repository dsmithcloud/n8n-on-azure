// Parameters
@description('Environment name (e.g., dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Workload name for the n8n deployment')
param workloadName string = 'n8n'

@description('Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Log retention period in days')
param logRetentionInDays int = 30

@description('Timezone for the n8n container')
param timezone string = 'UTC'

@description('Minimum number of container replicas should always be 1')
param minReplicas int = 1

@description('Maximum number of container replicas')
param maxReplicas int = 3

@description('CPU allocation for the container')
param cpuCores string = '1'

@description('Memory allocation for the container')
param memorySize string = '2Gi'

@description('SKU for the Key Vault')
param keyVaultSku string = 'standard'

@description('Secure random value for generating the n8n encryption key')
@secure()
param encryptionKeySeed string = newGuid()

// Application Gateway Parameters
@description('Application Gateway name')
param appGatewayName string = ''

@description('Application Gateway dedicated subnet ID')
param appGatewaySubnetId string = ''

@description('Public IP resource ID for Application Gateway frontend')
param publicIpId string = ''

@description('Key Vault certificate secret ID for TLS termination')
@secure()
param kvCertSecretId string

@description('Listener host names for Application Gateway')
param listenerHostNames array = ['n8n.smithdavid.pro']

@description('Application Gateway SKU name')
@allowed(['Standard_v2', 'WAF_v2'])
param skuName string = 'WAF_v2'

@description('Minimum autoscale instances')
param autoscaleMin int = 1

@description('Maximum autoscale instances')
param autoscaleMax int = 5

@description('Use HTTPS for backend communication')
param backendUseHttps bool = true

@description('Backend port number')
param backendPort int = 443

@description('Request timeout in seconds')
param requestTimeoutSeconds int = 240

@description('ACA backend IP addresses (preferred for private endpoints)')
param acaBackendIpAddresses array = []

@description('ACA backend FQDN')
param acaBackendFqdn string = ''

@description('Backend hostname for host header override when using IP addresses')
param backendHostName string = 'ca-n8n-dev-scus-yzgvift2xlpw6.delightfulground-bc547139.southcentralus.azurecontainerapps.io'

@description('Enable HTTP to HTTPS redirect')
param enableHttpRedirect bool = true

@description('Enable WAF protection')
param enableWaf bool = true

// Variables for CAF-compliant naming
var locationAbbreviations = {
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'
  centralus: 'cus'
  northcentralus: 'ncus'
  southcentralus: 'scus'
  westcentralus: 'wcus'
  canadacentral: 'cac'
  canadaeast: 'cae'
  brazilsouth: 'brs'
  northeurope: 'neu'
  westeurope: 'weu'
  uksouth: 'uks'
  ukwest: 'ukw'
  francecentral: 'frc'
  francesouth: 'frs'
  switzerlandnorth: 'szn'
  switzerlandwest: 'szw'
  norwayeast: 'noe'
  norwaywest: 'now'
  germanywestcentral: 'gwc'
  germanynorth: 'gn'
  swedencentral: 'sec'
  swedensouth: 'ses'
  eastasia: 'eas'
  southeastasia: 'seas'
  australiaeast: 'aue'
  australiasoutheast: 'ause'
  australiacentral: 'auc'
  australiacentral2: 'auc2'
  japaneast: 'jpe'
  japanwest: 'jpw'
  koreacentral: 'krc'
  koreasouth: 'krs'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southindia: 'sin'
  centralindia: 'cin'
  westindia: 'win'
  uaenorth: 'uan'
  uaecentral: 'uac'
}

var locationAbbr = locationAbbreviations[location]
var uniqueSuffix = uniqueString(resourceGroup().id)

// CAF-compliant resource names
var workspaceNameCAF = 'log-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var managedEnvironmentNameCAF = 'cae-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var containerAppNameCAF = 'ca-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var keyVaultNameCAF = 'kv-${workloadName}-${environment}-${locationAbbr}-${take(uniqueSuffix, 6)}'
var userAssignedMINameCAF = 'id-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var vnetNameCAF = 'vnet-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var appgwNameCAF = 'agw-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var wafPolicyNameCAF = 'wafpol-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var publicIPNameCAF = 'pip-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var nsgDefaultNameCAF = 'nsg-default-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var nsgAppGatewayNameCAF = 'nsg-appgw-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var nsgContainerAppNameCAF = 'nsg-ca-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var nsgExtraNameCAF = 'nsg-extra-${workloadName}-${environment}-${locationAbbr}-${uniqueSuffix}'
var privateDnsZoneNameCAF = '${location}.azurecontainerapps.io'

// Network Security Groups using AVM
module nsgDefault 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: 'nsg-default-deployment'
  params: {
    name: nsgDefaultNameCAF
    location: location
    securityRules: [
      {
        name: 'AllowInboundSSH'
        properties: {
          description: 'Allow inbound SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

module nsgAppGateway 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: 'nsg-appgw-deployment'
  params: {
    name: nsgAppGatewayNameCAF
    location: location
    securityRules: [
      {
        name: 'AllowInboundHTTP'
        properties: {
          description: 'Allow inbound HTTP traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowInboundHTTPS'
        properties: {
          description: 'Allow inbound HTTPS traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowApplicationGatewayV2'
        properties: {
          description: 'Allow Application Gateway v2 management traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
    ]
  }
}

module nsgContainerApp 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: 'nsg-ca-deployment'
  params: {
    name: nsgContainerAppNameCAF
    location: location
    securityRules: [
      {
        name: 'AllowInboundFromAppGateway'
        properties: {
          description: 'Allow inbound traffic from Application Gateway subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.0.0.32/27'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

module nsgExtra 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: 'nsg-extra-deployment'
  params: {
    name: nsgExtraNameCAF
    location: location
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          description: 'Deny all inbound traffic by default'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Virtual Network using AVM
module vnet 'br/public:avm/res/network/virtual-network:0.5.0' = {
  name: 'vnet-deployment'
  params: {
    name: vnetNameCAF
    location: location
    addressPrefixes: [
      '10.0.0.0/25'
    ]
    subnets: [
      {
        name: 'snet-default'
        addressPrefix: '10.0.0.0/27'
        networkSecurityGroupResourceId: nsgDefault.outputs.resourceId
      }
      {
        name: 'snet-appgw'
        addressPrefix: '10.0.0.32/27'
        networkSecurityGroupResourceId: nsgAppGateway.outputs.resourceId
      }
      {
        name: 'snet-containerapp'
        addressPrefix: '10.0.0.64/27'
        networkSecurityGroupResourceId: nsgContainerApp.outputs.resourceId
        delegation: 'Microsoft.App/environments'
      }
      {
        name: 'snet-extra'
        addressPrefix: '10.0.0.96/27'
        networkSecurityGroupResourceId: nsgExtra.outputs.resourceId
      }
    ]
  }
}

// Private DNS Zone for Container Apps using AVM
module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.5.0' = {
  name: 'private-dns-zone-deployment'
  params: {
    name: privateDnsZoneNameCAF
    location: 'global'
    virtualNetworkLinks: [
      {
        name: 'vnet-link-${vnetNameCAF}'
        virtualNetworkResourceId: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
  }
}

// Note: Create DNS A record manually after deployment using:
// FQDN=$(az containerapp show --name <container-app-name> --resource-group <rg> --query "properties.configuration.ingress.fqdn" -o tsv)
// STATIC_IP=$(az containerapp env show --name <env-name> --resource-group <rg> --query "properties.staticIp" -o tsv)
// RECORD_NAME=${FQDN%.<dns-zone>}
// az network private-dns record-set a add-record --zone-name <dns-zone> --resource-group <rg> --record-set-name "$RECORD_NAME" --ipv4-address $STATIC_IP --ttl 300

// Public IP for Application Gateway
module publicIP 'br/public:avm/res/network/public-ip-address:0.6.0' = {
  name: 'public-ip-deployment'
  params: {
    name: publicIPNameCAF
    location: location
    skuName: 'Standard'
    publicIPAllocationMethod: 'Static'
  }
}

// WAF Policy for Application Gateway using AVM
module wafPolicy 'br/public:avm/res/network/application-gateway-web-application-firewall-policy:0.2.0' = if (enableWaf) {
  name: 'waf-policy-deployment'
  params: {
    name: wafPolicyNameCAF
    location: location
    policySettings: {
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

// Application Gateway v2 with comprehensive configuration
// App Gateway must reside in a dedicated subnet.
// Key Vault–backed certificate requires MI permissions: get/list on secrets/certificates.
// When targeting ACA by IP, host header override is required to route correctly to the app.
resource appGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: !empty(appGatewayName) ? appGatewayName : appgwNameCAF
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceGroup().id}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${userAssignedMINameCAF}': {}
    }
  }
  properties: {
    sku: {
      name: skuName
      tier: skuName
    }
    autoscaleConfiguration: {
      minCapacity: autoscaleMin
      maxCapacity: autoscaleMax
    }
    firewallPolicy: enableWaf ? {
      id: resourceId('Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies', wafPolicyNameCAF)
    } : null
    enableHttp2: true
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-configuration'
        properties: {
          subnet: {
            id: !empty(appGatewaySubnetId) ? appGatewaySubnetId : '${vnet.outputs.resourceId}/subnets/snet-appgw'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appgw-frontend-ip'
        properties: {
          publicIPAddress: {
            id: !empty(publicIpId) ? publicIpId : publicIP.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'http-port'
        properties: {
          port: 80
        }
      }
      {
        name: 'https-port'
        properties: {
          port: 443
        }
      }
    ]
    sslCertificates: [
      {
        name: 'appgw-ssl-cert'
        properties: {
          keyVaultSecretId: kvCertSecretId
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'aca-backend-pool'
        properties: {
          backendAddresses: !empty(acaBackendFqdn) ? [
            {
              fqdn: acaBackendFqdn
            }
          ] : [
            {
              fqdn: containerApp.outputs.fqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'aca-backend-settings'
        properties: {
          port: backendPort
          protocol: backendUseHttps ? 'Https' : 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: requestTimeoutSeconds
          pickHostNameFromBackendAddress: !empty(acaBackendIpAddresses) ? false : true
          hostName: !empty(acaBackendIpAddresses) ? backendHostName : null
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'aca-readiness-probe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'aca-health-probe'
        properties: {
          protocol: 'Http'
          path: '/healthz'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: !empty(acaBackendIpAddresses) ? false : true
          host: !empty(acaBackendIpAddresses) ? backendHostName : null
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'aca-readiness-probe'
        properties: {
          protocol: 'Https'
          path: '/healthz/readiness'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: !empty(acaBackendIpAddresses) ? false : true
          host: !empty(acaBackendIpAddresses) ? backendHostName : null
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    httpListeners: concat([
      {
        name: 'appgw-https-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'appgw-frontend-ip')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'https-port')
          }
          protocol: 'Https'
          hostNames: listenerHostNames
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'appgw-ssl-cert')
          }
        }
      }
    ], enableHttpRedirect ? [
      {
        name: 'appgw-http-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'appgw-frontend-ip')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'http-port')
          }
          protocol: 'Http'
          hostNames: listenerHostNames
        }
      }
    ] : [])
    redirectConfigurations: enableHttpRedirect ? [
      {
        name: 'http-to-https-redirect'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'appgw-https-listener')
          }
          includePath: true
          includeQueryString: true
        }
      }
    ] : []
    requestRoutingRules: concat([
      {
        name: 'appgw-https-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'appgw-https-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'aca-backend-pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'aca-backend-settings')
          }
        }
      }
    ], enableHttpRedirect ? [
      {
        name: 'appgw-http-redirect-rule'
        properties: {
          ruleType: 'Basic'
          priority: 110
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'appgw-http-listener')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', (!empty(appGatewayName) ? appGatewayName : appgwNameCAF), 'http-to-https-redirect')
          }
        }
      }
    ] : [])
  }
}

// User-Assigned Managed Identity using AVM
module userAssignedMI 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'user-assigned-mi-deployment'
  params: {
    name: userAssignedMINameCAF
    location: location
  }
}

// Log Analytics Workspace using AVM
module workspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: 'workspace-deployment'
  params: {
    name: workspaceNameCAF
    location: location
    skuName: 'PerGB2018'
    dataRetention: logRetentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Key Vault using AVM
module keyVault 'br/public:avm/res/key-vault/vault:0.13.3' = {
  name: 'key-vault-deployment'
  params: {
    name: keyVaultNameCAF
    location: location
    enableVaultForDeployment: false
    enableVaultForDiskEncryption: false
    enableVaultForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
    sku: keyVaultSku
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    secrets: [
      {
        name: 'n8n-encryption-key'
        value: base64ToString(base64(uniqueString(keyVaultNameCAF, encryptionKeySeed, resourceGroup().id)))
      }
    ]
  }
}

// Container Apps Managed Environment using AVM
module managedEnvironment 'br/public:avm/res/app/managed-environment:0.11.3' = {
  name: 'managed-environment-deployment'
  params: {
    name: managedEnvironmentNameCAF
    location: location
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.outputs.logAnalyticsWorkspaceId
        sharedKey: workspace.outputs.primarySharedKey
      }
    }
    zoneRedundant: false
    internal: true
    infrastructureSubnetResourceId: '${vnet.outputs.resourceId}/subnets/snet-containerapp'
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
  }
  dependsOn: [
    privateDnsZone
  ]
}

// n8n Container App using AVM
module containerApp 'br/public:avm/res/app/container-app:0.19.0' = {
  name: 'container-app-deployment'
  params: {
    name: containerAppNameCAF
    location: location
    environmentResourceId: managedEnvironment.outputs.resourceId
    workloadProfileName: 'Consumption'
    managedIdentities: {
      userAssignedResourceIds: [userAssignedMI.outputs.resourceId]
    }
    containers: [
      {
        image: 'docker.io/n8nio/n8n:latest'
        name: containerAppNameCAF
        env: [
          {
            name: 'N8N_ENCRYPTION_KEY'
            secretRef: 'n8n-encryption-key'
          }
          {
            name: 'GENERIC_TIMEZONE'
            value: timezone
          }
          {
            name: 'WEBHOOK_URL'
            value: 'https://${containerAppNameCAF}.${managedEnvironment.outputs.defaultDomain}'
          }
          {
            name: 'TRUST_PROXY'
            value: 'true'
          }
          {
            name: 'N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS'
            value: 'true'
          }
        ]
        resources: {
          cpu: json(cpuCores)
          memory: memorySize
        }
      }
    ]
    secrets: [
      {
        name: 'n8n-encryption-key'
        keyVaultUrl: '${keyVault.outputs.uri}secrets/n8n-encryption-key'
        identity: userAssignedMI.outputs.resourceId
      }
    ]
    ingressExternal: true
    ingressTargetPort: 5678
    ingressTransport: 'auto'
    ingressAllowInsecure: false
    trafficWeight: 100
    trafficLatestRevision: true
    scaleSettings: {
      minReplicas: minReplicas
      maxReplicas: maxReplicas
    }
    activeRevisionsMode: 'Single'
  }
  dependsOn: [
    keyVaultSecretsUserRoleAssignment
  ]
}

// Role assignment for User-Assigned MI to access Key Vault secrets using AVM
module keyVaultSecretsUserRoleAssignment 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.1' = {
  name: 'key-vault-secrets-user-role-assignment'
  params: {
    principalId: userAssignedMI.outputs.principalId
    roleDefinitionIdOrName: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    principalType: 'ServicePrincipal'
    description: 'Grant user-assigned managed identity access to read Key Vault secrets'
  }
}

// Outputs
output containerAppFQDN string = containerApp.outputs.fqdn
output containerAppName string = containerAppNameCAF
output workspaceId string = workspace.outputs.resourceId
output workspaceName string = workspaceNameCAF
output managedEnvironmentId string = managedEnvironment.outputs.resourceId
output managedEnvironmentName string = managedEnvironmentNameCAF
output managedEnvironmentDefaultDomain string = managedEnvironment.outputs.defaultDomain
output keyVaultName string = keyVaultNameCAF
output keyVaultId string = keyVault.outputs.resourceId
output keyVaultUri string = keyVault.outputs.uri
output userAssignedManagedIdentityId string = userAssignedMI.outputs.resourceId
output userAssignedManagedIdentityName string = userAssignedMINameCAF
output userAssignedManagedIdentityPrincipalId string = userAssignedMI.outputs.principalId
output vnetId string = vnet.outputs.resourceId
output vnetName string = vnetNameCAF
output vnetAddressSpace string = '10.0.0.0/25'
output subnetDefault string = '10.0.0.0/27'
output subnetAppGateway string = '10.0.0.32/27'
output subnetContainerApp string = '10.0.0.64/27'
output subnetExtra string = '10.0.0.96/27'
output nsgDefaultId string = nsgDefault.outputs.resourceId
output nsgAppGatewayId string = nsgAppGateway.outputs.resourceId
output nsgContainerAppId string = nsgContainerApp.outputs.resourceId
output nsgExtraId string = nsgExtra.outputs.resourceId
output privateDnsZoneId string = privateDnsZone.outputs.resourceId
output privateDnsZoneName string = privateDnsZoneNameCAF
