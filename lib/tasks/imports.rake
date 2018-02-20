require 'csv'

namespace :import do
  desc "Notify parent imports when children finish"
  task notify_parent: :environment do
    ParentNotifier.new(Import).notify_when_finished
  end

  desc "Mark old unfinished Netex imports as 'aborted'"
  task netex_abort_old: :environment do
    NetexImport.abort_old
  end

  def importer_output_to_csv importer
    filepath = "./#{importer.configuration_name}_#{Time.now.strftime "%y%m%d%H%M"}_out.csv"
    cols = %w(line kind event message error)
    if importer.reload.journal.size > 0
      keys = importer.journal.first["row"].map(&:first)
      CSV.open(filepath, "w") do |csv|
        csv << cols + keys
        importer.journal.each do |j|
          csv << cols.map{|c| j[c]} + j["row"].map(&:last)
        end
      end
      puts "Import Output written in #{filepath}"
    end
  end

  desc "import the given file with the corresponding importer"
  task :import, [:configuration_name, :filepath, :referential_id] => :environment do |t, args|
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    if args[:referential_id].present?
      referential = Referential.find args[:referential_id]
      importer.configure do |config|
        config.add_value :referential, referential
        config.context = {referential: referential}
      end
    end
    puts "\e[33m***\e[0m Start importing"
    begin
      importer.import(verbose: true)
    rescue Interrupt
      raise
    ensure
      puts "\n\e[33m***\e[0m Import done, status: " + (importer.status == "success" ? "\e[32m" : "\e[31m" ) + (importer.status || "") + "\e[0m"
      importer_output_to_csv importer
    end
  end

  desc "import the given file with the corresponding importer in the given StopAreaReferential"
  task :import_in_stop_area_referential, [:referential_id, :configuration_name, :filepath] => :environment do |t, args|
    referential = StopAreaReferential.find args[:referential_id]
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    importer.configure do |config|
      config.add_value :stop_area_referential, referential
      config.context = {stop_area_referential: referential}
    end
    puts "\e[33m***\e[0m Start importing"
    begin
      importer.import(verbose: true)
    rescue Interrupt
      raise
    ensure
      puts "\n\e[33m***\e[0m Import done, status: " + (importer.status == "success" ? "\e[32m" : "\e[31m" ) + (importer.status || "") + "\e[0m"
      importer_output_to_csv importer
    end
  end

  desc "import the given routes files"
  task :import_routes, [:referential_id, :configuration_name, :mapping_filepath, :filepath] => :environment do |t, args|
    referential = Referential.find args[:referential_id]
    referential.switch
    stop_area_referential = referential.stop_area_referential
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    importer.configure do |config|
      config.add_value :stop_area_referential, referential
      config.context = {stop_area_referential: stop_area_referential, mapping_filepath: args[:mapping_filepath]}
    end
    puts "\e[33m***\e[0m Start importing"
    begin
      importer.import(verbose: true)
    rescue Interrupt
      raise
    ensure
      puts "\n\e[33m***\e[0m Import done, status: " + (importer.status == "success" ? "\e[32m" : "\e[31m" ) + (importer.status || "") + "\e[0m"
      importer_output_to_csv importer
    end
  end

  desc "import the given file with the corresponding importer in the given LineReferential"
  task :import_in_line_referential, [:referential_id, :configuration_name, :filepath] => :environment do |t, args|
    referential = LineReferential.find args[:referential_id]
    importer = SimpleImporter.create configuration_name: args[:configuration_name], filepath: args[:filepath]
    importer.configure do |config|
      config.add_value :line_referential, referential
      config.context = {line_referential: referential}
    end
    puts "\e[33m***\e[0m Start importing"
    begin
      importer.import(verbose: true)
    rescue Interrupt
      raise
    ensure
      puts "\n\e[33m***\e[0m Import done, status: " + (importer.status == "success" ? "\e[32m" : "\e[31m" ) + (importer.status || "") + "\e[0m"
      importer_output_to_csv importer
    end
  end
end
