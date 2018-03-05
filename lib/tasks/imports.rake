require 'csv'
require 'tasks/helpers/simple_interfaces'

namespace :import do
  desc "Notify parent imports when children finish"
  task notify_parent: :environment do
    ParentNotifier.new(Import).notify_when_finished
  end

  desc "Mark old unfinished Netex imports as 'aborted'"
  task netex_abort_old: :environment do
    NetexImport.abort_old
  end

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

  desc "import the given file with the corresponding importer in the given StopAreaReferential"
  task :import_in_stop_area_referential, [:referential_id, :configuration_name, :filepath, :logs_output_dir] => :environment do |t, args|
    args.with_defaults(logs_output_dir: "./log/importers/")
    FileUtils.mkdir_p args[:logs_output_dir]

    referential = StopAreaReferential.find args[:referential_id]
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    importer.configure do |config|
      config.add_value :stop_area_referential, referential
      config.context = {stop_area_referential: referential, logs_output_dir: args[:logs_output_dir]}
    end

    SimpleInterfacesHelper.run_interface_controlling_interruption importer, :import, args
  end

  desc "import the given routes files"
  task :import_routes, [:referential_id, :configuration_name, :mapping_filepath, :filepath, :logs_output_dir] => :environment do |t, args|
    args.with_defaults(logs_output_dir: "./log/importers/")
    FileUtils.mkdir_p args[:logs_output_dir]

    referential = Referential.find args[:referential_id]
    referential.switch
    stop_area_referential = referential.stop_area_referential
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    importer.configure do |config|
      config.add_value :stop_area_referential, referential
      config.context = {stop_area_referential: stop_area_referential, line_referential: line_referential, mapping_filepath: args[:mapping_filepath], logs_output_dir: args[:logs_output_dir]}
    end

    SimpleInterfacesHelper.run_interface_controlling_interruption importer, :import, args
  end

  desc "import the given file with the corresponding importer in the given LineReferential"
  task :import_in_line_referential, [:referential_id, :configuration_name, :filepath, :logs_output_dir] => :environment do |t, args|
    args.with_defaults(logs_output_dir: "./log/importers/")
    FileUtils.mkdir_p args[:logs_output_dir]

    referential = LineReferential.find args[:referential_id]
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    importer.configure do |config|
      config.add_value :line_referential, referential
      config.context = {line_referential: referential, logs_output_dir: args[:logs_output_dir]}
    end

    SimpleInterfacesHelper.run_interface_controlling_interruption importer, :import, args
  end
end
