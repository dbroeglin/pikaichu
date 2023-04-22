task :log => :environment do
  ActiveRecord::Base.logger = Logger.new($stdout)
end
