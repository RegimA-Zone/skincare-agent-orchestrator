@description('Name of the Application Insights resource')
param appInsightsName string
@description('Location for Application Insights')
param location string = resourceGroup().location
@description('Tags for the resource')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
  tags: tags
}

output connectionString string = appInsights.properties.ConnectionString
