// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

@description('Location for the network resources')
param location string

@description('Name of the virtual network')
param vnetName string

@description('Name of the app service subnet')
param appServiceSubnetName string

@description('Virtual network address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('App service subnet address prefix')
param appServiceSubnetAddressPrefix string = '10.0.1.0/24'

@description('Tags for network resources')
param tags object = {}

// Network Security Group for App Service subnet
resource appServiceNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${appServiceSubnetName}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureServicesOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 1010
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

// App Service Subnet
resource appServiceSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnet
  name: appServiceSubnetName
  properties: {
    addressPrefix: appServiceSubnetAddressPrefix
    networkSecurityGroup: {
      id: appServiceNsg.id
    }
    delegations: [
      {
        name: 'Microsoft.Web.serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
    serviceEndpoints: [
      {
        service: 'Microsoft.KeyVault'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.Storage'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.Web'
        locations: [
          location
        ]
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output appServiceSubnetId string = appServiceSubnet.id
output appServiceSubnetName string = appServiceSubnetName
output nsgId string = appServiceNsg.id
