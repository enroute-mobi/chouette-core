module SimpleInterfacesHelper
  def self.interface_output_to_csv interface, output_dir
    FileUtils.mkdir_p output_dir
    filepath =  File.join output_dir, + "#{interface.configuration_name}_#{Time.now.strftime "%y%m%d%H%M"}_out.csv"
    cols = %w(line kind event message error)
    if interface.reload.journal.size > 0 && interface.journal.first["row"].present?
      keys = interface.journal.first["row"].map(&:first)
      CSV.open(filepath, "w") do |csv|
        csv << cols + keys
        interface.journal.each do |j|
          csv << cols.map{|c| j[c]} + j["row"].map(&:last)
        end
      end
      puts "Task Output written in #{filepath}"
    end
  end

  def self.run_interface_controlling_interruption interface, method, args
    begin
      interface.send(method, verbose: true)
    rescue Interrupt
      raise
    ensure
      puts "\n\e[33m***\e[0m Done, status: " + (interface.status == "success" ? "\e[32m" : "\e[31m" ) + (interface.status || "") + "\e[0m"
      interface_output_to_csv interface, args[:logs_output_dir]
    end
  end
end
