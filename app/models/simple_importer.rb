# coding: utf-8
class SimpleImporter < SimpleInterface
  def resolve col_name, value, &block
    val = block.call(value)
    return val if val.present?
    @resolution_queue[[col_name.to_s, value]].push({record: @current_record, attribute: @current_attribute, block: block})
    nil
  end

  def import opts={}
    configuration.validate!

    fail_with_error "File not found: #{self.filepath}" do
      @number_of_lines = CSV.read(self.filepath, self.configuration.csv_options).length
    end

    init_env opts

    @resolution_queue = Hash.new{|h,k| h[k] = []}

    self.configuration.before_actions(:parsing).each do |action| action.call self end

    @statuses = ""

    if ENV["NO_TRANSACTION"]
      process_csv_file
    else
      ActiveRecord::Base.transaction do
        process_csv_file
      end
    end
    self.status ||= :success
  rescue SimpleInterface::FailedOperation
    self.status = :failed
  ensure
    self.save!
  end

  def encode_string s
    s.encode("utf-8").force_encoding("utf-8")
  end

  def dump_csv_from_context
    dir = context[:logs_output_dir] || "log/importers"
    filepath = File.join dir, "#{self.configuration_name}_#{Time.now.strftime "%y%m%d%H%M"}.csv"
    # for some reason, context[:csv].to_csv does not work
    CSV.open(filepath, 'w') do |csv|
      header = true
      context[:csv].each do |row|
        csv << row.headers if header
        csv << row.fields
        header = false
      end
    end
    log "CSV file dumped in #{filepath}"
  end

  protected

  def process_csv_file
    self.configuration.before_actions(:all).each do |action| action.call self end
    log "Starting import ...", color: :green

    (context[:csv] || CSV.read(filepath, self.configuration.csv_options)).each do |row|
      @current_row = row
      @new_status = nil
      begin
        handle_row row
        fail_with_error ->(){ @current_record.errors.messages } do
          new_record = @current_record&.new_record?
          @new_status ||= new_record ? colorize("✓", :green) : colorize("-", :orange)
          @event = new_record ? :creation : :update
          self.configuration.before_actions(:each_save).each do |action|
            action.call self, @current_record
          end
          ### This could fail if the record has a mandatory relation which is not yet resolved
          ### TODO: do not attempt to save if the current record if waiting for resolution
          ###       and fail at the end if there remains unresolved relations
          if @current_record
            if self.configuration.ignore_failures
              unless @current_record.save
                @new_status = colorize("x", :red)
                push_in_journal({message: "errors: #{@current_record.errors.messages}", error: "invalid record", event: :error, kind: :error})
              end
            else
              @current_record.save!
            end
          end
          self.configuration.after_actions(:each_save).each do |action|
            action.call self, @current_record
          end
        end
      rescue SimpleInterface::FailedRow
        @new_status = colorize("x", :red)
      end
      push_in_journal({event: @event, kind: :log}) if @current_record&.valid?
      @statuses += @new_status
      self.configuration.columns.each do |col|
        if @current_record && col.name && @resolution_queue.any?
          val = @current_record.send col[:attribute]
          (@resolution_queue.delete([col.name, val]) || []).each do |res|
            record = res[:record]
            attribute = res[:attribute]
            value = res[:block].call(val, record)
            record.send "#{attribute}=", value
            record.save!
          end
        end
      end
      print_state
      @current_line += 1
    end

    begin
      self.configuration.after_actions(:all).each do |action|
        action.call self
      end
    rescue SimpleInterface::FailedRow
    end
  end

  def handle_row row
    if self.configuration.get_custom_handler
      instance_exec(row, &self.configuration.get_custom_handler)
    else
      fail_with_error "", abort_row: true do
        @current_record = self.configuration.find_record row
        self.configuration.columns.each do |col|
          @current_attribute = col[:attribute]
          val = col[:value]
          if val.nil? || val.is_a?(Proc)
            if row.has_key? col.name
              if val.is_a?(Proc)
                val = instance_exec(row[col.name], &val)
              else
                val = row[col.name]
              end
            else
              push_in_journal({event: :column_not_found, message: "Column not found: #{col.name}", kind: :warning})
              self.status ||= :success_with_warnings
            end
          end

          if val.nil? && col.required?
            raise "MISSING VALUE FOR COLUMN #{col.name}"
          end
          val = encode_string(val) if val.is_a?(String)
          @current_record.send "#{@current_attribute}=", val if val
        end
      end
    end
  end

  class Configuration < SimpleInterface::Configuration
    attr_accessor :model

    def initialize import_name, opts={}
      super import_name, opts
      @model = opts[:model]
    end

    def options
      super.update({model: model})
    end

    def validate!
      raise "Incomplete configuration, missing model for #{@import_name}" unless model.present?
    end
  end
end
