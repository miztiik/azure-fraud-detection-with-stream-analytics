// targetScope = 'subscription'

targetScope = 'resourceGroup'

// Parameters
param deploymentParams object
param identityParams object

param storageAccountParams object
param logAnalyticsWorkspaceParams object
param funcParams object
param eventHubParams object
param serviceBusParams object
param cosmosDbParams object
param streamAnalyticsParams object

param brandTags object

param dateNow string = utcNow('yyyy-MM-dd-hh-mm')

param tags object = union(brandTags, {last_deployed:dateNow})


// Create Identity
module r_uami 'modules/identity/create_uami.bicep' = {
  name: '${deploymentParams.enterprise_name_suffix}_${deploymentParams.loc_short_code}_${deploymentParams.global_uniqueness}_uami'
  params: {
    deploymentParams:deploymentParams
    identityParams:identityParams
    tags: tags
  }
}

// Create Cosmos DB
module r_cosmosdb 'modules/database/cosmos.bicep' ={
  name: '${cosmosDbParams.cosmosDbNamePrefix}_${deploymentParams.loc_short_code}_${deploymentParams.global_uniqueness}_cosmos_db'
  params: {
    deploymentParams:deploymentParams
    cosmosDbParams:cosmosDbParams
    tags: tags
  }
}

// Create the Log Analytics Workspace
module r_logAnalyticsWorkspace 'modules/monitor/log_analytics_workspace.bicep' = {
  name: '${logAnalyticsWorkspaceParams.workspaceName}_${deploymentParams.loc_short_code}_${deploymentParams.global_uniqueness}_la'
  params: {
    deploymentParams:deploymentParams
    logAnalyticsWorkspaceParams: logAnalyticsWorkspaceParams
    tags: tags
  }
}


// Create Storage Account
module r_sa 'modules/storage/create_storage_account.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.loc_short_code}_${deploymentParams.global_uniqueness}_sa'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    funcParams: funcParams
    tags: tags
  }
}


// Create Storage Account - Blob container
module r_blob 'modules/storage/create_blob.bicep' = {
  name: '${storageAccountParams.storageAccountNamePrefix}_${deploymentParams.loc_short_code}_${deploymentParams.global_uniqueness}_blob'
  params: {
    deploymentParams:deploymentParams
    storageAccountParams:storageAccountParams
    storageAccountName: r_sa.outputs.saName
    storageAccountName_1: r_sa.outputs.saName_1
    logAnalyticsWorkspaceId: r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId
    enableDiagnostics: false
  }
  dependsOn: [
    r_sa
    r_logAnalyticsWorkspace
  ]
}

// Create the function app & Functions
module r_fn_app 'modules/functions/create_function.bicep' = {
  name: '${funcParams.funcNamePrefix}_${deploymentParams.loc_short_code}_${deploymentParams.global_uniqueness}_fn_app'
  params: {
    deploymentParams:deploymentParams
    uami_name_func: r_uami.outputs.uami_name_func
    funcParams: funcParams
    funcSaName: r_sa.outputs.saName_1

    logAnalyticsWorkspaceId: r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId
    enableDiagnostics: true
    tags: tags

    // appConfigName: r_appConfig.outputs.appConfigName

    saName: r_sa.outputs.saName
    blobContainerName: r_blob.outputs.blobContainerName

    cosmos_db_accnt_name: r_cosmosdb.outputs.cosmos_db_accnt_name
    cosmos_db_name: r_cosmosdb.outputs.cosmos_db_name
    cosmos_db_container_name: r_cosmosdb.outputs.cosmos_db_container_name

    event_hub_ns_name: r_event_hub.outputs.event_hub_ns_name
    event_hub_name: r_event_hub.outputs.event_hub_name
    event_hub_sale_events_consumer_group_name: r_event_hub.outputs.event_hub_sale_events_consumer_group_name

    svc_bus_ns_name: r_svc_bus.outputs.svc_bus_ns_name
    svc_bus_q_name: r_svc_bus.outputs.svc_bus_q_name
  }
  dependsOn: [
    r_sa
    r_logAnalyticsWorkspace
  ]
}


// Create the Service Bus & Queue
module r_svc_bus 'modules/integration/create_svc_bus.bicep' = {
  // scope: resourceGroup(r_rg.name)
  name: '${serviceBusParams.serviceBusNamePrefix}_${deploymentParams.loc_short_code}_${deploymentParams.global_uniqueness}_svc_bus'
  params: {
    deploymentParams:deploymentParams
    serviceBusParams:serviceBusParams
    tags: tags
  }
}


// Create Stream Analytics
module r_stream_analytics 'modules/integration/create_stream_analytics.bicep' = {
  name: '${eventHubParams.eventHubNamePrefix}_${deploymentParams.global_uniqueness}_stream_analytics'
  params: {
    deploymentParams:deploymentParams
    streamAnalyticsParams:streamAnalyticsParams
    tags: tags

    uami_name_stream_analytics: r_uami.outputs.uami_name_stream_analytics

    saName: r_sa.outputs.saName
    blobContainerName: r_blob.outputs.blobContainerName

    cosmos_db_accnt_name: r_cosmosdb.outputs.cosmos_db_accnt_name

    event_hub_ns_name: r_event_hub.outputs.event_hub_ns_name
    event_hub_name: r_event_hub.outputs.event_hub_name
    event_hub_sale_events_consumer_group_name: r_event_hub.outputs.event_hub_sale_events_consumer_group_name

    svc_bus_ns_name: r_svc_bus.outputs.svc_bus_ns_name
    svc_bus_q_name: r_svc_bus.outputs.svc_bus_q_name

    logAnalyticsPayGWorkspaceId: r_logAnalyticsWorkspace.outputs.logAnalyticsPayGWorkspaceId
  }
}

// Create Event Hub
module r_event_hub 'modules/integration/create_event_hub.bicep' = {
  name: '${eventHubParams.eventHubNamePrefix}_${deploymentParams.global_uniqueness}_event_Hub'
  params: {
    deploymentParams:deploymentParams
    eventHubParams:eventHubParams
    tags: tags

    saName: r_sa.outputs.saName
    blobContainerName: r_blob.outputs.blobContainerName
  }
}
