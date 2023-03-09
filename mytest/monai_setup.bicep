// This BICEP script will fully provision a functional monai sandbox

// IMPORTANT: This setup is intended only for demo purpose. The data is still accessible
// by the users when opening the storage accounts, and data exfiltration is easy.

// For a given set of regions, it will provision:
// - an AzureML workspace and compute cluster for orchestration

// Usage (sh):
// > az login
// > az account set --name <subscription name>
// > az group create --name <resource group name> --location <region>
// > az deployment group create --template-file .\mlops\bicep\monaix_setup.bicep \
//                              --resource-group <resource group name \
//                              --parameters demoBaseName="monaidemoams1"

targetScope = 'resourceGroup'

// please specify the base name for all resources
@description('Base name of the demo, used for creating all resources as prefix')
param demoBaseName string = 'monaidemoams1'

// below parameters are optionals and have default values
@allowed(['UserAssigned','SystemAssigned'])
@description('Type of identity to use for permissions model')
param identityType string = 'UserAssigned'

@description('Region of the orchestrator (workspace, central storage and compute).')
param orchestratorRegion string = resourceGroup().location

@description('The VM used for creating compute clusters in orchestrator and silos.')
param compute1SKU string = 'Standard_NC4as_T4_v3'

@description('Tags to curate the resources in Azure.')
param tags object = {
  Owner: 'AzureML Samples'
  Project: 'azure-ml-federated-learning'
  Environment: 'dev'
  Toolkit: 'bicep'
  Docs: 'https://github.com/Azure-Samples/azure-ml-federated-learning'
}

// Create Azure Machine Learning workspace
module workspace './modules/azureml/open_azureml_workspace.bicep' = {
  name: '${demoBaseName}-aml-${orchestratorRegion}'
  scope: resourceGroup()
  params: {
    baseName: demoBaseName
    machineLearningName: 'aml-${demoBaseName}'
    machineLearningDescription: 'Azure ML demo workspace for monai (use for dev purpose only)'
    location: orchestratorRegion
    tags: tags
  }
}

// Create an orchestrator compute+storage pair and attach to workspace
module orchestrator './modules/fl_pairs/open_compute_storage_pair.bicep' = {
  name: '${demoBaseName}-compute'
  scope: resourceGroup()
  params: {
    machineLearningName: workspace.outputs.workspaceName
    machineLearningRegion: orchestratorRegion

    pairRegion: orchestratorRegion
    tags: tags

    pairBaseName: '${demoBaseName}-compute'

    compute1Name: 'compute-01' // let's not use demo base name in cluster name
    compute1SKU: compute1SKU
    
    datastoreName: 'datastore_monai' // let's not use demo base name

    // identity for permissions model
    identityType: identityType

    // set R/W permissions for orchestrator UAI towards orchestrator storage
    applyDefaultPermissions: true
  }
  dependsOn: [
    workspace
  ]
}


