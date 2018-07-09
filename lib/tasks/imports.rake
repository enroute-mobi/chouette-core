require 'csv'
require 'tasks/helpers/simple_interfaces'

namespace :import do
  desc "import the given file with the corresponding importer"
  task :import, [:configuration_name, :filepath, :referential_id, :logs_output_dir] => :environment do |t, args|
    args.with_defaults(logs_output_dir: "./log/importers/")
    FileUtils.mkdir_p args[:logs_output_dir]

    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]

    if args[:referential_id].present?
      referential = Referential.find args[:referential_id]
      importer.configure do |config|
        config.add_value :referential, referential
        config.context = {referential: referential, logs_output_dir: args[:logs_output_dir]}
      end
    end

    SimpleInterfacesHelper.run_interface_controlling_interruption importer, :import, args
  end

end
