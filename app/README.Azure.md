# Setup

    index=003
    environment=test
    resource_group=rg-pikaichu-$environment-$index

    az group create --location francecentral --resource-group $resource_group


    az containerapp env create \
        --name cae-pikaichu-$environment-$suffix \
        --resource-group $resource_group \
        --location francecentral

    az containerapp up \
        --name ca-pikaichu-$environment-$suffix \
        --resource-group $resource_group \
        --location francecentral \
        --environment cae-pikaichu-$environment-$suffix \
        --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
        --target-port 80 \
        --ingress external \
        --query properties.configuration.ingress.fqdn





# Cleanup

  az group delete --resource-group $resource_group