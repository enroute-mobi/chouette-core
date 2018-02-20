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
  task :import, [:configuration_name, :filepath] => :environment do |t, args|
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    puts "\e[33m***\e[0m Start importing"
    importer.import(verbose: true)
    puts "\n\e[33m***\e[0m Import done, status: " + (importer.status == "success" ? "\e[32m" : "\e[31m" ) + importer.status + "\e[0m"
  end

  desc "import the given file with the corresponding importer in the given StopAreaReferential"
  task :import_stop_areas_in_referential, [:referential_id, :configuration_name, :filepath] => :environment do |t, args|
    referential = StopAreaReferential.find args[:referential_id]
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    importer.configure do |config|
      config.add_value :stop_area_referential, referential
    end
    puts "\e[33m***\e[0m Start importing"
    importer.import(verbose: true)
    puts "\n\e[33m***\e[0m Import done, status: " + (importer.status == "success" ? "\e[32m" : "\e[31m" ) + importer.status + "\e[0m"
  end
end
