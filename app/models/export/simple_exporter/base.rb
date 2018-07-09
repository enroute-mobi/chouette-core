class Export::SimpleExporter::Base < Export::Base
  after_commit :call_exporter, on: :create
  attr_accessor :synchronous

  option :filepath

  def self.user_visible?
    false
  end

  def self.inherited child
    super child
    child.options = @options
    child.instance_eval do
      def self.user_visible?
        true
      end
    end
  end

  def call_exporter
    return if @skip_callback
    if self.synchronous
      do_call_exporter
    else
      SimpleExportWorker.perform_async(id)
    end
  end

  def simple_exporter_configuration_name
  end

  def exporter
    @exporter ||= begin
      if options[:_exporter_id]
        exporter = SimpleJsonExporter.find options[:_exporter_id]
      else
        exporter = SimpleJsonExporter.create configuration_name: simple_exporter_configuration_name
        options[:_exporter_id] = exporter.id
      end
      exporter
    end
  end

  def configure_exporter config
  end

  def do_call_exporter
    @skip_callback = true
    tmp_dir = Dir.mktmpdir
    tmp = File.new(File.join(tmp_dir, "#{archive_name}.json"), 'w+')
    referential.switch
    self.filepath = tmp.path
    exporter.configure do |config|
      configure_exporter config
    end
    exporter.filepath = self.filepath
    exporter.export
    set_status_from_exporter
    convert_exporter_journal_to_messages
    self.save!
    @skip_callback = false
    upload_file tmp
  end

  def set_status_from_exporter
    if exporter.status.to_s == "error"
      self.status = :failed
    elsif exporter.status.to_s == "success"
      self.status = :successful
    else
      self.status = :warning
    end
  end

  def convert_exporter_journal_to_messages
    self.messages.destroy_all
    exporter.journal.each do |journal_item|
      journal_item.symbolize_keys!
      vals = {}

      if journal_item[:kind].to_s == "warning"
        vals[:criticity] = :warning
      elsif journal_item[:kind].to_s == "error"
        vals[:criticity] = :error
      else
        vals[:criticity] = :info
        if journal_item[:event].to_s == "success"
          vals[:message_key] = :success
        end
      end
      vals[:resource_attributes] = journal_item[:row]

      if journal_item[:message].present?
        vals[:message_key] = :full_text
        vals[:message_attributes] = {
          text: journal_item[:message]
        }
      end
      vals[:message_attributes] ||= {}
      vals[:message_attributes][:line] =  journal_item[:line]
      self.messages.build vals
    end
  end
end
