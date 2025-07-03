// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param location string
param msiName string
param tags object = {}

resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: msiName
  location: location
  tags: tags
}

// Assign Monitoring Metrics Publisher role to the managed identity
resource monitoringMetricsPublisherRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(msi.id, '3913510d-42f4-4e42-8a64-420c390055eb')
  scope: msi
  properties: {
    roleDefinitionId: '/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb'
    principalId: msi.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output msiID string = msi.id
output msiName string = msi.name
output msiClientID string = msi.properties.clientId
output msiPrincipalID string = msi.properties.principalId
