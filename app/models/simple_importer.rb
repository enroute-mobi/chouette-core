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

  def context
    self.configuration.context
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
    @errors = []
    @messages = []
    @number_of_lines = 0
    @padding = 1
    @current_line = 0
    fail_with_error "File not found: #{self.filepath}" do
      @number_of_lines = CSV.read(self.filepath, self.configuration.csv_options).length
      @padding = [1, Math.log(@number_of_lines, 10).ceil()].max
    end


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
  rescue FailedImport
    self.status = :failed
  ensure
    self.save!
  end

  def fail_with_error msg=nil, opts={}
    begin
      yield
    rescue => e
      msg = msg.call if msg.is_a?(Proc)
      custom_print "\nFAILED: \n errors: #{msg}\n exception: #{e.message}\n#{e.backtrace.join("\n")}", color: :red unless self.configuration.ignore_failures
      push_in_journal({message: msg, error: e.message, event: :error, kind: :error})
      @new_status = colorize("x", :red)
      if self.configuration.ignore_failures
        raise FailedRow if opts[:abort_row]
      else
        raise FailedImport
      end
    end
  end

  def encode_string s
    s.encode("utf-8").force_encoding("utf-8")
  end

  def dump_csv_from_context
    filepath = "./#{self.configuration_name}_#{Time.now.strftime "%y%m%d%H%M"}.csv"
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

  def log msg, opts={}
    msg = colorize msg, opts[:color] if opts[:color]
    if opts[:append]
      @messages[-1] = (@messages[-1] || "") + msg
    else
      @messages << msg
    end
    print_state
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
      rescue FailedRow
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
    rescue FailedRow
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

  def push_in_journal data
    line = @current_line + 1
    line += 1 if configuration.headers
    self.journal.push data.update(line: line, row: @current_row)
    if data[:kind] == :error || data[:kind] == :warning
      @errors.push data
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

  def print_state
    return unless @verbose

    @status_width ||= begin
      term_width = %x(tput cols).to_i
      term_width - @padding - 10
    rescue
      100
    end

    @status_height ||= begin
      term_height = %x(tput lines).to_i
      term_height - 3
    rescue
      50
    end

    full_status = @statuses || ""
    full_status = full_status.last(@status_width*10) || ""
    padding_size = [(@number_of_lines - @current_line - 1), (@status_width - full_status.size/10)].min
    full_status = "#{full_status}#{"."*[padding_size, 0].max}"

    msg = "#{"%#{@padding}d" % (@current_line + 1)}/#{@number_of_lines}: #{full_status}"

    lines_count = [(@status_height / 2) - 3, 1].max

    if @messages.any?
      msg += "\n\n"
      msg += colorize "=== MESSAGES (#{@messages.count}) ===\n", :green
      msg += "[...]\n" if @messages.count > lines_count
      msg += @messages.last(lines_count).join("\n")
      msg += "\n"*[lines_count-@messages.count, 0].max
    end

    if @errors.any?
      msg += "\n\n"
      msg += colorize "=== ERRORS (#{@errors.count}) ===\n", :red
      msg += "[...]\n" if @errors.count > lines_count
      msg += @errors.last(lines_count).map do |j|
        kind = j[:kind]
        kind = colorize(kind, kind == :error ? :red : :orange)
        encode_string "[#{kind}]\t\tL#{j[:line]}\t#{j[:error]}\t\t#{j[:message]}"
      end.join("\n")
    end
    custom_print msg, clear: true
  end

  def custom_print msg, opts={}
    return unless @verbose
    out = ""
    msg = colorize(msg, opts[:color]) if opts[:color]
    puts "\e[H\e[2J" if opts[:clear]
    out += msg
    print out
  end

  class FailedImport < RuntimeError
  end

  class FailedRow < RuntimeError
  end

  class Configuration
    attr_accessor :model, :headers, :separator, :key, :context, :encoding, :ignore_failures, :scope
    attr_reader :columns

    def initialize import_name, opts={}
      @import_name = import_name
      @key = opts[:key] || "id"
      @headers = opts.has_key?(:headers) ? opts[:headers] : true
      @separator = opts[:separator] || ","
      @encoding = opts[:encoding]
      @columns = opts[:columns] || []
      @model = opts[:model]
      @custom_handler = opts[:custom_handler]
      @before = opts[:before]
      @after = opts[:after]
      @ignore_failures = opts[:ignore_failures]
      @context = opts[:context] || {}
      @scope = opts[:scope]
    end

    def duplicate
      Configuration.new @import_name, self.options
    end

    def options
      {
        key: @key,
        headers: @headers,
        separator: @separator,
        encoding: @encoding,
        columns: @columns.map(&:duplicate),
        model: model,
        custom_handler: @custom_handler,
        before: @before,
        after: @after,
        ignore_failures: @ignore_failures,
        context: @context,
        scope: @scope
      }
    end

    def validate!
      raise "Incomplete configuration, missing model for #{@import_name}" unless model.present?
    end

    def attribute_for_col col_name
      column = self.columns.find{|c| c.name == col_name}
      column && column[:attribute] || col_name
    end

    def record_scope
      _scope = @scope
      _scope = instance_exec(&_scope) if _scope.is_a?(Proc)
      _scope || model
    end

    def find_record attrs
      record_scope.find_or_initialize_by(attribute_for_col(@key) => attrs[@key.to_s])
    end

    def csv_options
      {
        headers: self.headers,
        col_sep: self.separator,
        encoding: self.encoding
      }
    end

    def add_column name, opts={}
      @columns.push Column.new({name: name.to_s}.update(opts))
    end

    def add_value attribute, value
      @columns.push Column.new({attribute: attribute, value: value})
    end

    def before group=:all, &block
      @before ||= Hash.new{|h, k| h[k] = []}
      @before[group].push block
    end

    def after group=:all, &block
      @after ||= Hash.new{|h, k| h[k] = []}
      @after[group].push block
    end

    def before_actions group=:all
      @before ||= Hash.new{|h, k| h[k] = []}
      @before[group]
    end

    def after_actions group=:all
      @after ||= Hash.new{|h, k| h[k] = []}
      @after[group]
    end

    def custom_handler &block
      @custom_handler = block
    end

    def get_custom_handler
      @custom_handler
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

      def required?
        !!@options[:required]
      end

      def [](key)
        @options[key]
      end
    end
  end
end
