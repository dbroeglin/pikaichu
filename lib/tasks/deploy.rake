namespace :deploy do
  namespace :azure do
    desc "Deploy"
    task deploy: :environment do
      sh %(
        azd deploy
      )
    end
  end
end
