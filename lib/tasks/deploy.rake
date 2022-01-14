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
  end
end