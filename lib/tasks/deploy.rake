# rubocop:disable Layout/LineLength


namespace :deploy do
  desc "Deploy staging"
  task staging: :environment do
    sh 'bin/rails db:drop'
    sh 'bin/rails db:create'
    sh 'bin/rails db:migrate'
    sh 'bin/rails ops:db:fixtures:full'

    sh 'bin/rails test test/controllers'
    # sh 'bin/rails rubocop'

    sh 'git push staging'

    sh 'pg_dump -cO pikaichu_development | heroku psql -a pikaichu-staging'
  end

  namespace :azure do
    acr_name = "acrpikaichu001"
    kv_name = "kvpikaichu001"
    hub_rg_name = "rg-pikaichu-production-001"

    index = "002"
    region = 'francecentral'
    azenv = Rails.env
    suffix = "pikaichu-#{azenv}-#{index}"
    rg_name = "rg-#{suffix}"
    acr_server = "#{acr_name}.azurecr.io"
    cae_name = "cae-#{suffix}"
    ca_name = "ca-#{suffix}"
    image_name = "#{acr_server}/pikaichu:#{Rails.env}"
    pg_name = "pg-#{suffix}"
    db_name = "pikaichu_#{Rails.env}"
    secret_name = "DATABASE-URL-#{azenv.upcase}-#{index}"
    pg_url = ""

    public_ip = ""

    desc "Env"
    task env: :environment do
      puts "Execute for environment '#{Rails.env}'..."
      raise "Set the PG_ADMIN_PASSWORD environment variable, pls." unless ENV['PG_ADMIN_PASSWORD']
      raise "Set the SECRET_KEY_BASE environment variable, pls." unless ENV['SECRET_KEY_BASE']

      public_ip = `dig +short myip.opendns.com @resolver1.opendns.com`.strip
      pg_url = "postgres://pikaichu:#{ENV.fetch('PG_ADMIN_PASSWORD', nil)}@#{pg_name}.postgres.database.azure.com/#{db_name}?sslmode=require"
    end

    desc "Deploy Hub"
    task hub: :env do
      # TODO: create also KV
      sh %(
        az acr create --resource-group #{rg_name} --name #{acr_name} --sku Basic
        az acr login --name #{acr_name}
      )
    end

    desc "Deploy Azure Foundation"
    task foundation: :env do
      sh %(
        az group create --name #{rg_name} --location '#{region}'
      )
    end

    desc "Build Image and publish to Azure ACR"
    task publish: :environment do
      sh "az acr login -n #{acr_name}"
      sh "docker build --tag pikaichu_#{Rails.env} ."
      sh "docker tag pikaichu_#{Rails.env} #{acr_server}/pikaichu:#{Rails.env}"
      sh "docker push #{acr_server}/pikaichu:#{Rails.env}"

      if Rails.env.production?
        sh "git tag -f previous_prod production"
        sh "git tag -f production"
      end
    end

    desc "Deploy image to Container Apps"
    task deploy: :environment do
      sh %(
          az containerapp up \
            --name #{ca_name} \
            --image #{image_name} \
            --resource-group #{rg_name} \
            --environment #{cae_name} \
            --ingress external \
            --target-port 80
        )
    end

    desc "Deploy Azure Foundation"
    task postgresql: :foundation do
      sh %(
        az postgres flexible-server create \
          --resource-group #{rg_name} \
          --name #{pg_name} \
          --tier Burstable \
          --sku-name Standard_B1ms \
          --storage-size 32 \
          --public #{public_ip}-#{public_ip} \
          --admin-user pikaichu \
          --admin-password #{ENV.fetch('PG_ADMIN_PASSWORD', nil)} \
          --output json

        az postgres flexible-server firewall-rule create \
          --resource-group #{rg_name} \
          --name #{pg_name} \
          -r azure \
          --start-ip-address 0.0.0.0 \
          --end-ip-address 0.0.0.0
        )
      sh %(

        az postgres flexible-server db create \
          --resource-group #{rg_name} \
          --server-name #{pg_name} \
          --database-name pikaichu_#{Rails.env}
      )

      sh %(
        az keyvault secret set \
          --vault-name #{kv_name} \
          --name #{secret_name} \
          --value '#{pg_url}'
      )
    end

    desc "Deploy Azure Foundation"
    task containerapp: :foundation do
      sh %(
        az containerapp env create \
          --name #{cae_name} \
          --resource-group #{rg_name} \
          --location #{region}
      )
    
      sh %(
        az containerapp create \
          --name #{ca_name} \
          --resource-group #{rg_name} \
          --environment #{cae_name} \
          --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
          --target-port 80 \
          --ingress external \
          --system-assigned \
          --env-vars "RAILS_ENV=#{Rails.env}" "SECRET_KEY_BASE=#{ENV.fetch('SECRET_KEY_BASE', nil)}" \
          --query properties.configuration.ingress.fqdn
      )

      sh %(
        az role assignment create \
          --assignee `az containerapp show --resource-group #{rg_name} --name #{ca_name} -o json --query identity.principalId -o tsv` \
          --scope `az acr show --resource-group #{hub_rg_name} --name #{acr_name} --query id -o tsv` \
          --role "AcrPull"
      )

      sh %(
        az containerapp connection create keyvault \
          --connection keyvault \
          --name #{ca_name} \
          --container #{ca_name} \
          --resource-group #{rg_name} \
          --target-resource-group #{hub_rg_name} \
          --vault #{kv_name} \
          --system-identity \
          --client-type None
      )

      sh %(
        az containerapp connection create postgres-flexible \
          --connection postgresql \
          --name #{ca_name} \
          --resource-group #{rg_name} \
          --name #{ca_name} \
          --container #{ca_name} \
          --target-resource-group #{rg_name} \
          --server #{pg_name} \
          --database #{db_name} \
          --client-type none \
          --secret name=pikaichu secret-uri=https://#{kv_name}.vault.azure.net/secrets/#{secret_name} \
          --customized-keys AZURE_POSTGRESQL_PASSWORD=DATABASE_URL
      ) 

      sh %(
        az containerapp registry set \
          --name #{ca_name} \
          --resource-group #{rg_name} \
          --identity system \
          --server #{acr_server}
      )

      sh %(
        az containerapp update \
          --name #{ca_name} \
          --resource-group #{rg_name} \
          --image #{image_name}
      )

      sh %(
        az containerapp exec \
          --name #{ca_name} \
          --resource-group #{rg_name} \
          --command "bin/rails db:migrate"

        az containerapp revision restart \
          --name #{ca_name} \
          --resource-group #{rg_name} \
          --revision `az containerapp revision list -g #{rg_name} -n #{ca_name} -o tsv --query '[].name'`
      )
    end

    desc "Deploy PostgreSQL FW rule for my current IP"
    task pg_fw: :env do
      sh %(
        az postgres flexible-server firewall-rule create \
          --resource-group #{rg_name} \
          --name #{pg_name} \
          -r home \
          --start-ip-address #{public_ip} \
          --end-ip-address #{public_ip}
        )
    end

    desc "Deploy all"
    task all: [:docker, :foundation, :postgresql, :webapp] do
    end
  end
end
