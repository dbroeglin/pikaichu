namespace :ops do
  def pg_dump
    var_name = "AZURE_DATABASE_URL"
    raise "Set the #{var_name} environment variable, pls." unless ENV[var_name]

    "pg_dump --clean --if-exists --no-owner --no-privileges --no-comments --schema public '#{ENV.fetch(var_name, nil)}'"
  end

  def my_ip
    `dig +short myip.opendns.com @resolver1.opendns.com`.strip
  end

  namespace :db do
    namespace :copy do
      desc "Copy production database"
      task production: :environment do
        sh "#{pg_dump} | psql pikaichu_production"
      end
    end

    namespace :backup do
      desc "Backup production database"
      task production: :environment do
        my_ip = my_ip()
        rg_name = "rg-pikaichu-production-002"
        server_name = `az postgres flexible-server list --resource-group #{rg_name} --query '[0].name' --output tsv`.strip

        raise "Unable to get server name from Azure" if server_name.empty?

        sh "az postgres flexible-server firewall-rule update " \
          "--name #{server_name} --resource-group #{rg_name} " \
          "--rule-name Backup --start-ip-address #{my_ip} --end-ip-address #{my_ip}"
        sh "#{pg_dump} | gzip -9 > ../backups/pikaichu_#{DateTime.now.strftime('%Y-%m-%d_%H-%M-%S')}.sql.gz"
      end
    end
  end
end
