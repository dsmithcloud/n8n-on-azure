// Parameters
@description('Name for the n8n container app')
param containerAppName string = 'n8n'

@description('Name for the Log Analytics workspace')
param workspaceName string = 'workspace-${uniqueString(resourceGroup().id)}'

@description('Name for the Container Apps managed environment')
param managedEnvironmentName string = 'managedEnvironment-${uniqueString(resourceGroup().id)}'

@description('Azure region where resources will be deployed')
param location string = resourceGroup().location

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

@description('Name for the Key Vault')
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'

@description('SKU for the Key Vault')
param keyVaultSku string = 'standard'

@description('Tenant ID for the Key Vault access policies')
param tenantId string = tenant().tenantId

@description('Secure random value for generating the n8n encryption key')
@secure()
param encryptionKeySeed string = newGuid()

// Log Analytics Workspace
resource workspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
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
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        dynamicJsonColumns: false
      }
    }
    zoneRedundant: false
    kedaConfiguration: {}
    daprConfiguration: {}
    customDomainConfiguration: {}
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
    publicNetworkAccess: 'Enabled'
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: keyVaultName
  location: location
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
        external: true
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
              value: 'https://${containerAppName}.${managedEnvironment.properties.defaultDomain}'
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
