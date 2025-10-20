This template can be deployed to any Azure subscription using:​

az deployment group create \
  --resource-group <your-resource-group> \
  --template-file n8n-deployment.bicep \
  --parameters n8nEncryptionKey='<your-secure-encryption-key>'
