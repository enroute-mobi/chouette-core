class SimpleImporter < ActiveRecord::Base
  attr_accessor :configuration

  def self.define name
    @importers ||= {}
    configuration = Configuration.new name
    yield configuration
    configuration.validate!
    @importers[name.to_sym] = configuration
  end

  def self.find_configuration name
    @importers ||= {}
    configuration = @importers[name.to_sym]
    raise "Importer not found: #{name}" unless configuration
    configuration
  end

  def initialize *args
    super *args
    self.configuration = self.class.find_configuration self.configuration_name
    self.journal ||= []
  end

  def configure
    new_config = configuration.duplicate
    yield new_config
    new_config.validate!
    self.configuration = new_config
  end

  def resolve col_name, value, &block
    val = block.call(value)
    return val if val.present?
    @resolution_queue[[col_name.to_s, value]].push({record: @current_record, attribute: @current_attribute, block: block})
    nil
  end

  def import opts={}
    @verbose = opts.delete :verbose
    @resolution_queue = Hash.new{|h,k| h[k] = []}
    number_of_lines = 0
    padding = 1
    fail_with_error "File not found: #{self.filepath}" do
      number_of_lines = CSV.read(self.filepath, self.configuration.csv_options).length
      padding = [1, Math.log(number_of_lines, 10).ceil()].max
    end

    current_line = 0
    status = :success
    statuses = ""
    log "#{"%#{padding}d" % 0}/#{number_of_lines}", clear: true
    CSV.foreach(filepath, self.configuration.csv_options) do |row|
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
            self.journal.push({event: :column_not_found, message: "Column not found: #{col.name}", kind: :warning})
            status = :success_with_warnings
          end
        end
        @current_record.send "#{@current_attribute}=", val if val
      end

      fail_with_error ->(){ @current_record.errors.messages } do
        new_record = @current_record.new_record?
        @current_record.save!
        self.journal.push({event: (new_record ? :creation : :update), kind: :log})
        statuses += new_record ? colorize("✓", :green) : colorize("-", :orange)
      end
      self.configuration.columns.each do |col|
        if col.name && @resolution_queue.any?
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
      current_line += 1
      log "#{"%#{padding}d" % current_line}/#{number_of_lines}: #{statuses}", clear: true
    end
    self.update_attribute :status, status
  rescue FailedImport
    self.update_attribute :status, :failed
  ensure
    self.save
  end

  protected

  def fail_with_error msg
    begin
      yield
    rescue => e
      msg = msg.call if msg.is_a?(Proc)
      log "\nFAILED: \n errors: #{msg}\n exception: #{e.message}\n#{e.backtrace.join("\n")}", color: :red
      self.journal.push({message: msg, error: e.message, event: :error, kind: :error})
      self.save
      raise FailedImport
    end
  end

  def colorize txt, color
    color = {
      red: "31",
      green: "32",
      orange: "33",
    }[color] || "33"
    "\e[#{color}m#{txt}\e[0m"
  end

  def log msg, opts={}
    return unless @verbose
    out = ""
    msg = colorize(msg, opts[:color]) if opts[:color]
    if opts[:clear] && @prev_msg_size
      out += "\b"*@prev_msg_size
    end
    out += msg
    print out
    @prev_msg_size = msg.size
  end

  class FailedImport < RuntimeError
  end

  class Configuration
    attr_accessor :model, :headers, :separator, :key
    attr_reader :columns

    def initialize import_name, opts={}
      @import_name = import_name
      @key = opts[:key] || "id"
      @headers = opts.has_key?(:headers) ? opts[:headers] : true
      @separator = opts[:separator] || ","
      @columns = opts[:columns] || []
      @model = opts[:model]
    end

    def duplicate
      Configuration.new @import_name, self.options
    end

    def options
      {
        key: @key,
        headers: @headers,
        separator: @separator,
        columns: @columns.map(&:duplicate),
        model: model
      }
    end

    def validate!
      raise "Incomplete configuration, missing model for #{@import_name}" unless model.present?
    end

    def attribute_for_col col_name
      column = self.columns.find{|c| c.name == col_name}
      column && column[:attribute] || col_name
    end

    def find_record attrs
      model.find_or_initialize_by(attribute_for_col(@key) => attrs[@key.to_s])
    end

    def csv_options
      {
        headers: self.headers,
        col_sep: self.separator
      }
    end

    def add_column name, opts={}
      @columns.push Column.new({name: name.to_s}.update(opts))
    end

    def add_value attribute, value
      @columns.push Column.new({attribute: attribute, value: value})
    end

    class Column
      attr_accessor :name
      def initialize opts={}
        @name = opts[:name]
        @options = opts
        @options[:attribute] ||= @name
      end

      def duplicate
        Column.new @options.dup
      end

      def [](key)
        @options[key]
      end
    end
  end
end
