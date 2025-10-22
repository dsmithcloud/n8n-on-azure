// Parameters
@description('Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Application name for resource naming')
param applicationName string = 'n8n'

@description('Environment name (dev, test, prod)')
param environment string = 'prod'

@description('Project or workload identifier')
param workloadName string = 'workflow'

@description('Optional instance identifier for multiple deployments')
param instance string = '001'

@description('Common tags to be applied to all resources')
param tags object = {
  Environment: environment
  Application: applicationName
  Workload: workloadName
  CostCenter: 'USEC COGS CSU-FSI-1010'
  Owner: 'smithdavid'
  CreatedBy: 'Bicep'
  DeploymentDate: utcNow('yyyy-MM-dd')
}

// CAF Naming Variables
var resourceSuffix = '${workloadName}-${environment}-${location}-${instance}'
var containerAppName = 'ca-${applicationName}-${resourceSuffix}'
var workspaceName = 'log-${applicationName}-${resourceSuffix}'
var managedEnvironmentName = 'cae-${applicationName}-${resourceSuffix}'
var keyVaultName = 'kv-${applicationName}-${take(uniqueString(resourceGroup().id), 8)}'
var vnetName = 'vnet-${applicationName}-${resourceSuffix}'
var containerAppsSubnetName = 'snet-ca-${applicationName}-${resourceSuffix}'
var appGatewaySubnetName = 'snet-agw-${applicationName}-${resourceSuffix}'
var appGatewayName = 'agw-${applicationName}-${resourceSuffix}'
var frontDoorProfileName = 'afd-${applicationName}-${resourceSuffix}'
var frontDoorEndpointName = '${applicationName}-ep-${environment}'
var publicIpName = 'pip-agw-${applicationName}-${resourceSuffix}'

@description('Log retention period in days')
param logRetentionInDays int = 30

@description('Timezone for the n8n container')
param timezone string = 'UTC'

@description('Minimum number of container replicas')
param minReplicas int = 0

@description('Maximum number of container replicas')
param maxReplicas int = 10

@description('CPU allocation for the container')
param cpuCores string = '1'

@description('Memory allocation for the container')
param memorySize string = '2Gi'

@description('SKU for the Key Vault')
param keyVaultSku string = 'standard'

@description('Tenant ID for the Key Vault access policies')
param tenantId string = tenant().tenantId

@description('Secure random value for generating the n8n encryption key')
@secure()
param encryptionKeySeed string = newGuid()

@description('Enable VNet integration for Container Apps environment')
param enableVNetIntegration bool = false

@description('Enable external access via Application Gateway and Front Door')
param enableExternalAccess bool = true

@description('Virtual Network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Container Apps subnet address prefix')
param containerAppsSubnetPrefix string = '10.0.0.0/23'

@description('Application Gateway subnet address prefix')  
param appGatewaySubnetPrefix string = '10.0.2.0/24'

// Virtual Network (conditional)
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = if (enableVNetIntegration) {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: containerAppsSubnetName
        properties: {
          addressPrefix: containerAppsSubnetPrefix
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewaySubnetPrefix
        }
      }
    ]
  }
}

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionInDays
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: json('-1')
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Container Apps Managed Environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2025-02-02-preview' = {
  name: managedEnvironmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
        dynamicJsonColumns: false
      }
    }
    zoneRedundant: false
    kedaConfiguration: {}
    daprConfiguration: {}
    customDomainConfiguration: {}
    vnetConfiguration: enableVNetIntegration ? {
      infrastructureSubnetId: '${vnet.id}/subnets/${containerAppsSubnetName}'
      internal: true
    } : null
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
        enableFips: false
      }
    ]
    peerAuthentication: {
      mtls: {
        enabled: false
      }
    }
    peerTrafficConfiguration: {
      encryption: {
        enabled: false
      }
    }
    publicNetworkAccess: enableVNetIntegration ? 'Disabled' : 'Enabled'
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
    sku: {
      name: keyVaultSku
      family: 'A'
    }
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Role assignment for Container App to access Key Vault secrets
resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerApp.id, keyVault.id, '4633458b-17de-408a-b874-0445c86b69e6')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// n8n encryption key secret in Key Vault
resource n8nEncryptionKeySecret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: keyVault
  name: 'n8n-encryption-key'
  properties: {
    value: base64ToString(base64(uniqueString(keyVault.id, encryptionKeySeed, resourceGroup().id)))
  }
}

// n8n Container App
resource containerApp 'Microsoft.App/containerapps@2025-02-02-preview' = {
  name: containerAppName
  location: location
  tags: tags
  kind: 'containerapps'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: managedEnvironment.id
    environmentId: managedEnvironment.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: enableVNetIntegration ? false : true
        targetPort: 5678
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
        stickySessions: {
          affinity: 'none'
        }
      }
      identitySettings: []
      secrets: [
        {
          name: 'n8n-encryption-key'
          keyVaultUrl: n8nEncryptionKeySecret.properties.secretUri
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'docker.io/n8nio/n8n:latest'
          imageType: 'ContainerImage'
          name: containerAppName
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
              value: enableVNetIntegration && enableExternalAccess 
                ? 'https://n8n-endpoint-${uniqueString(resourceGroup().id)}.z01.azurefd.net' 
                : 'https://${containerAppName}.${managedEnvironment.properties.defaultDomain}'
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
          probes: []
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        cooldownPeriod: 300
        pollingInterval: 30
      }
      volumes: []
    }
  }
}

// Public IP for Application Gateway
resource appGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (enableVNetIntegration && enableExternalAccess) {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'agw-${applicationName}-${take(uniqueString(resourceGroup().id), 8)}'
    }
  }
}

// Application Gateway
resource appGateway 'Microsoft.Network/applicationGateways@2023-11-01' = if (enableVNetIntegration && enableExternalAccess) {
  name: appGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 1
    }
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${appGatewaySubnetName}'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: appGatewayPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'n8nBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: containerApp.properties.configuration.ingress.fqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'n8nRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'n8nBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
  }
}

// Azure Front Door Profile
resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = if (enableVNetIntegration && enableExternalAccess) {
  name: frontDoorProfileName
  location: 'Global'
  tags: tags
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {}
}

// Front Door Endpoint
resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = if (enableVNetIntegration && enableExternalAccess) {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Front Door Origin Group
resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = if (enableVNetIntegration && enableExternalAccess) {
  name: 'n8n-origin-group'
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

// Front Door Origin
resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = if (enableVNetIntegration && enableExternalAccess) {
  name: 'n8n-origin'
  parent: frontDoorOriginGroup
  dependsOn: [
    appGateway
    appGatewayPublicIP
  ]
  properties: {
    hostName: 'agw-${applicationName}-${take(uniqueString(resourceGroup().id), 8)}.${location}.cloudapp.azure.com'
    httpPort: 80
    httpsPort: 443
    originHostHeader: 'agw-${applicationName}-${take(uniqueString(resourceGroup().id), 8)}.${location}.cloudapp.azure.com'
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

// Front Door Route
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = if (enableVNetIntegration && enableExternalAccess) {
  name: 'n8n-route'
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

// Outputs
output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn
output containerAppName string = containerApp.name
output workspaceId string = workspace.id
output workspaceName string = workspace.name
output managedEnvironmentId string = managedEnvironment.id
output managedEnvironmentName string = managedEnvironment.name
output managedEnvironmentDefaultDomain string = managedEnvironment.properties.defaultDomain
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output vnetId string = enableVNetIntegration ? vnet.id : ''
output vnetName string = enableVNetIntegration ? vnet.name : ''
output appGatewayFQDN string = (enableVNetIntegration && enableExternalAccess) ? 'agw-${applicationName}-${take(uniqueString(resourceGroup().id), 8)}.${location}.cloudapp.azure.com' : ''
output frontDoorEndpointHostName string = (enableVNetIntegration && enableExternalAccess) ? '${frontDoorEndpointName}-${take(uniqueString(resourceGroup().id), 8)}.azurefd.net' : ''
output isVNetIntegrated bool = enableVNetIntegration
output hasExternalAccess bool = enableExternalAccess
