# rubocop:disable Layout/LineLength

if Rails.env.development? || Rails.env.test?

  namespace :deploy do
    desc "Deploy staging"
    task staging: :environment do
      sh 'bin/rails db:drop'
      sh 'bin/rails db:create'
      sh 'bin/rails db:migrate'
      sh 'bin/rails ops:db:fixtures:full'

      sh 'bin/rails test test/controllers'
      #sh 'bin/rails rubocop'

      sh 'git push staging'

      sh 'pg_dump -cO pikaichu_development | heroku psql -a pikaichu-staging'
    end

    namespace :azure do
      index = "001"
      region = 'West Europe'
      suffix = "pikaichu-production-#{index}"
      rg_name = "rg-#{suffix}"
      acr_name = "acrpikaichu#{index}"
      acr_server = "#{acr_name}.azurecr.io"
      plan_name = "plan-#{suffix}"
      webapp_name = "app-#{suffix}"
      image_name = "#{acr_server}/pikaichu:production"
      pg_name = "pg-#{suffix}"
      pg_url = ""

      public_ip = `dig +short myip.opendns.com @resolver1.opendns.com`.strip

      desc "Env"
      task env: :environment do
        raise "Set the PG_ADMIN_PASSWORD environment variable, pls." unless ENV['PG_ADMIN_PASSWORD']
        raise "Set the SECRET_KEY_BASE environment variable, pls." unless ENV['SECRET_KEY_BASE']

        pg_url = "postgres://pikaichu:#{ENV['PG_ADMIN_PASSWORD']}@#{pg_name}.postgres.database.azure.com/postgres?sslmode=require"
      end

      desc "Deploy Azure Foundation"
      task foundation: :env do
        sh %(
          az group create --name #{rg_name} --location '#{region}'
        )
        sh %(
          az acr create --resource-group #{rg_name} --name #{acr_name} --sku Basic
          az acr login --name #{acr_name}
        )
      end

      desc "Deploy Image to Azure ACR"
      task :image do
        sh "az acr login -n #{acr_name}"
        sh "docker build --tag pikaichu_production ."
        sh "docker tag pikaichu_production #{acr_server}/pikaichu:production"
        sh "docker push #{acr_server}/pikaichu:production"
      end

      desc "Deploy Azure Foundation"
      task postgresql: :foundation do
        sh %(
          az postgres flexible-server create --resource-group #{rg_name} --name #{pg_name} --public #{public_ip}-#{public_ip} --admin-user pikaichu --admin-password #{ENV['PG_ADMIN_PASSWORD']} --output json
          az postgres flexible-server firewall-rule create --resource-group #{rg_name} --name #{pg_name} -r azure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

          )
      end

      desc "Deploy Posgresql FW rule for my current IP"
      task pg_fw: :env do
        sh %(
          MY_CURRENT_IP=`dig +short myip.opendns.com @resolver4.opendns.com`
          az postgres flex<cible-server firewall-rule create --resource-group #{rg_name} --name #{pg_name} -r home --start-ip-address $MY_CURRENT_IP --end-ip-address $MY_CURRENT_IP
          )
      end

      desc "Deploy Azure Foundation"
      task webapp: :foundation do
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
          az webapp config appsettings set --settings SECRET_KEY_BASE="#{ENV['SECRET_KEY_BASE']}" --name #{webapp_name} --resource-group #{rg_name}

        )

        sh %(
          az role assignment create --assignee #{principal_id} --scope /subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.ContainerRegistry/registries/#{acr_name} --role "AcrPull"
        )

        sh %(
          az resource update --ids /subscriptions/#{subscription_id}/resourceGroups/#{rg_name}/providers/Microsoft.Web/sites/#{webapp_name}/config/web --set properties.acrUseManagedIdentityCreds=True
        )

        webhook_url = `az webapp deployment container config --name #{webapp_name} --resource-group #{rg_name} --enable-cd true --query CI_CD_URL --output tsv`.strip

        sh "az acr webhook create --name pikaichu --registry #{acr_name}" \
           " --resource-group #{rg_name} --actions push --uri '#{webhook_url}'" \
           " --scope 'pikaichu:*'"
      end

      desc "Deploy all"
      task all: [:docker, :foundation, :postgresql, :webapp] do
      end
    end
  end
end
