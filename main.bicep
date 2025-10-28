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
    internal: false
    publicNetworkAccess: 'Enabled'
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
  }
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
