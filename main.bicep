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

@description('N8N encryption key (must be set)')
@secure()
param n8nEncryptionKey string

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

// n8n Container App
resource containerApp 'Microsoft.App/containerapps@2025-02-02-preview' = {
  name: containerAppName
  location: location
  kind: 'containerapps'
  identity: {
    type: 'None'
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
              value: n8nEncryptionKey
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
