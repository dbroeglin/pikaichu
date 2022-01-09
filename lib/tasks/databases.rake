if Rails.env.development? || Rails.env.test?

  namespace :db do
    namespace :copy do
      desc "Copy production database"
      task production: :environment do
        url = `heroku pg:credentials:url -a pikaichu`.split("\n").last.strip

        sh "pg_dump -cO #{url} | psql pikaichu_production"
      end
    end

    namespace :backup do
      desc "Backup production database"
      task production: :environment do
        url = `heroku pg:credentials:url -a pikaichu`.split("\n").last.strip

        sh "pg_dump -cO #{url} > ../backups/pikaichu_#{DateTime.now.strftime('%Y-%m-%d_%H-%M-%S')}.sql"
      end
    end
 end
end