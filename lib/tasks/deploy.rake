# rubocop:disable Layout/LineLength

if Rails.env.development? || Rails.env.test?

  namespace :deploy do
    desc "Deploy staging"
    task staging: :environment do
      sh 'bin/rails db:drop'
      sh 'bin/rails db:create'
      sh 'bin/rails db:migrate'
      sh 'bin/rails dev:prime'

      sh 'bin/rails test test/controllers'

      sh 'git push staging'

      sh 'pg_dump -cO pikaichu_development | heroku psql -a pikaichu-staging'
    end

    desc "Deploy Azure"
    task azure: :environment do
      raise "Please PG_ADMIN_PASSWORD environment variable" unless ENV['PG_ADMIN_PASSWORD']

      index = "002"
      suffix = "pikaichu-prod-#{index}"
      rg_name = "rg-#{suffix}"
      acr_name = "acrpikaichu#{index}"
      acr_server = "#{acr_name}.azurecr.io"
      plan_name = "plan-#{suffix}"
      webapp_name = "app-#{suffix}"
      image_name = "#{acr_server}/pikaichu:production"
      pg_name = "pg-#{suffix}"
      pg_url = "postgres://pikaichu:#{ENV['PG_ADMIN_PASSWORD']}@#{pg_name}.postgres.database.azure.com/postgres?sslmode=require"

      sh %(
        az group create --name #{rg_name} --location 'West Europe'
      )
      sh %(
        az acr create --resource-group #{rg_name} --name #{acr_name} --sku Basic
        az acr login --name #{acr_name}
      )

      sh %(
        docker build --tag pikaichu_production .
        docker tag pikaichu_production #{acr_server}/pikaichu:production
        docker push #{acr_server}/pikaichu:production
      )

      sh %(
       # az postgres flexible-server create --resource-group #{rg_name} --name #{pg_name} --public 185.39.141.109-185.39.141.109 --admin-user pikaichu --admin-password #{ENV['PG_ADMIN_PASSWORD']} --output json
       #az postgres flexible-server firewall-rule create --resource-group #{rg_name} --name #{pg_name} --start-ip-address 0.0.0.0

      )
      sh %(
        az appservice plan create --name #{plan_name} --resource-group #{rg_name} --sku B1 --is-linux
      )

      sh %(
        az webapp create  --name #{webapp_name} --deployment-container-image-name #{image_name} --plan #{plan_name} --resource-group #{rg_name}
      )
      sh %(
        az webapp config appsettings set --resource-group #{rg_name} --name #{webapp_name} --settings WEBSITES_PORT=80
      )

      principal_id = `az webapp identity assign --resource-group #{rg_name} --name #{webapp_name} --query principalId --output tsv`.strip
      subscription_id = `az account show --query id --output tsv`.strip

      # in between principal_id gen and role assignment to temporize???
      sh %(
        az webapp config appsettings set --settings RAILS_ENV=production --name #{webapp_name} --resource-group #{rg_name}
        az webapp config appsettings set --settings DATABASE_URL="#{pg_url}" --name #{webapp_name} --resource-group #{rg_name}
      )

      sh %(
        az role assignment create --assignee #{principal_id} --scope /subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.ContainerRegistry/registries/#{acr_name} --role "AcrPull"
      )

      sh %(
        az resource update --ids /subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Web/sites/#{webapp_name}/config/web --set properties.acrUseManagedIdentityCreds=True
      )
    end
  end
end