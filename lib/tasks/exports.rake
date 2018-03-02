require 'csv'
require 'tasks/helpers/simple_interfaces'

namespace :export do
  desc "Notify parent imports when children finish"
  task notify_parent: :environment do
    ParentNotifier.new(Import).notify_when_finished
  end

  desc "Mark old unfinished Netex imports as 'aborted'"
  task netex_abort_old: :environment do
    NetexImport.abort_old
  end

  desc "export companies in the give LineReferential using the given exporter"
  task :companies, [:referential_id, :configuration_name, :filepath, :logs_output_dir] => :environment do |t, args|
    args.with_defaults(filepath: "./companies.csv", logs_output_dir: "./log/exporters/")
    FileUtils.mkdir_p args[:logs_output_dir]

    referential = LineReferential.find args[:referential_id]
    exporter = SimpleExporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    exporter.configure do |config|
      config.collection = referential.companies.order(:name)
    end

    SimpleInterfacesHelper.run_interface_controlling_interruption exporter, :export, args
  end

  desc "export lines in the give LineReferential using the given exporter"
  task :lines, [:referential_id, :configuration_name, :filepath, :logs_output_dir] => :environment do |t, args|
    args.with_defaults(filepath: "./companies.csv", logs_output_dir: "./log/exporters/")
    FileUtils.mkdir_p args[:logs_output_dir]

    referential = LineReferential.find args[:referential_id]
    exporter = SimpleExporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    exporter.configure do |config|
      config.collection = referential.lines.order(:name)
    end

    SimpleInterfacesHelper.run_interface_controlling_interruption exporter, :export, args
  end

  desc "export a complete offer from the gicen referential in the given X next days"
  task :full_offer, [:referential_id, :timelapse, :configuration_name, :output_dir, :logs_output_dir] => :environment do |t, args|
    args.with_defaults(filepath: "./companies.csv", logs_output_dir: "./log/exporters/")
  end
end
