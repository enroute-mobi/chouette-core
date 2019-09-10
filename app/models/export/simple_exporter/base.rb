class Export::SimpleExporter::Base < Export::Base
  after_commit :call_exporter_async, on: :create

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

  def call_exporter_async
    enqueue_job :export!
  end

  def export!
    update(status: 'running', started_at: Time.now)
    call_exporter
    update(ended_at: Time.now)
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

  def call_exporter
    tmp = Tempfile.new [simple_exporter_configuration_name.to_s, ".json"]
    referential.switch
    exporter.configure do |config|
      configure_exporter config
    end
    exporter.filepath = tmp.path
    exporter.export
    set_status_from_exporter
    convert_exporter_journal_to_messages
    self.save!
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
