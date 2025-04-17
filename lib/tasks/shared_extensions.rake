# frozen_string_literal: true

namespace :db do
  desc 'Also create `postgis_schema` schema'
  task extensions: :environment do
    ActiveRecord::Base.configurations.configs_for(env_name: ActiveRecord::Tasks::DatabaseTasks.env).each do |db_config|
      ActiveRecord::Base.establish_connection(db_config)
      postgis_schema = db_config.configuration_hash[:postgis_schema]

      # Create Schema
      ActiveRecord::Base.connection.execute("CREATE SCHEMA IF NOT EXISTS #{postgis_schema};")
      # Grant usage to public
      ActiveRecord::Base.connection.execute("GRANT ALL ON SCHEMA #{postgis_schema} TO PUBLIC;")
    end
  end
end

Rake::Task["db:create"].enhance do
  Rake::Task["db:extensions"].invoke
end

Rake::Task["db:test:purge"].enhance do
  Rake::Task["db:extensions"].invoke
end
