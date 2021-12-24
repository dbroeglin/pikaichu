if Rails.env.development?
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new do |task|
    task.requires << 'rubocop-rails'
  end
end