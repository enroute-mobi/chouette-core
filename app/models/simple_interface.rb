class SimpleInterface < ApplicationModel
  attr_accessor :configuration, :interfaces_group

  class << self
    def configuration_class
      "#{self.name}::Configuration".constantize
    end

    def define name
      @importers ||= {}
      configuration = configuration_class.new name
      yield configuration if block_given?
      @importers[name.to_sym] = configuration
    end

    def find_configuration name
      @importers ||= {}
      configuration = @importers[name.to_sym]
      raise "#{self.name} not found: #{name}" unless configuration
      configuration
    end
  end

  def initialize *args
    super *args
    self.configuration = self.class.find_configuration self.configuration_name
    self.journal ||= []
  end

  def configuration
    @configuration ||= self.class.find_configuration self.configuration_name
  end

  def init_env opts
    @verbose = opts.delete :verbose

    @_errors = []
    @messages = []
    @padding = 1
    @current_line = -1
    @number_of_lines ||= 1
    @padding = [1, Math.log([@number_of_lines, 1].max, 10).ceil()].max
    @output_dir = opts[:output_dir] || Rails.root.join('tmp', self.class.name.tableize)
    @start_time = Time.now
  end

  def configure
    new_config = configuration.duplicate
    yield new_config
    self.configuration = new_config
  end

  def context
    self.configuration.context
  end

  def fail_with_error msg=nil, opts={}
    begin
      yield
    rescue => e
      msg = msg.call if msg.is_a?(Proc)
      custom_print "\nFAILED: \n errors: #{msg}\n exception: #{e.message}\n#{e.backtrace.join("\n")}", color: :red unless self.configuration.ignore_failures
      push_in_journal({message: msg, error: e.message, event: :error, kind: :error})
      @new_status = colorize("x", :red)
      self.status = :success_with_errors
      if self.configuration.ignore_failures
        raise SimpleInterface::FailedRow if opts[:abort_row]
      else
        raise FailedOperation
      end
    end
  end

  def log msg, opts={}
    msg = msg.to_s
    msg = colorize msg, opts[:color] if opts[:color]
    @start_time ||= Time.now
    time = Time.now - @start_time
    @messages ||= []
    if opts[:append]
      _time, _msg = @messages.pop || []
      _time ||= time
      _msg ||= ""
      @messages.push [_time, _msg+msg]
    elsif opts[:replace]
      @messages.pop
      @messages << [time, msg]
    else
      @messages << [time, msg]
    end
    print_state true
  end

  def output_filepath
    @output_filepath ||= File.join @output_dir, "#{self.configuration_name}_#{Time.now.strftime "%y%m%d%H%M"}_out.csv"
  end

  def write_output_to_csv
    cols = %i(line kind event message error)
    journal = self.journal && self.journal.map(&:symbolize_keys)
    first_row = journal.find{|r| r[:row].present? }
    if first_row.present?
      log "Writing output log"
      FileUtils.mkdir_p @output_dir
      keys = first_row[:row].map(&:first)
      CSV.open(output_filepath, "w") do |csv|
        csv << cols + keys
        journal.each do |j|
          csv << cols.map{|c| j[c]} + (j[:row] || {}).map(&:last)
        end
      end
      log "Output written in #{output_filepath}", replace: true
    end
  end

  protected

  def task_finished
    log "Saving..."
    self.save!
    log "Saved", replace: true
    write_output_to_csv
    log "FINISHED, status: "
    log status, color: SimpleInterface.status_color(status), append: true
    print_state true
  end

  def push_in_journal data
    line = (@current_line || 0) + 1
    line += 1 if configuration.headers
    @_errors ||= []
    self.journal.push data.update(line: line, row: @current_row)
    if data[:kind] == :error || data[:kind] == :warning
      @_errors.push data
    end
  end

  def self.colorize txt, color
    color = {
      red: "31",
      green: "32",
      orange: "33",
    }[color] || "33"
    "\e[#{color}m#{txt}\e[0m"
  end

  def self.status_color status
    color = :green
    color = :orange if status.to_s == "success_with_warnings"
    color = :red if status.to_s == "success_with_errors"
    color = :red if status.to_s == "error"
    color
  end

  def colorize txt, color
    SimpleInterface.colorize txt, color
  end

  def print_state force=false
    return unless @verbose
    return if !@last_repaint.nil? && (Time.now - @last_repaint < 0.1) && !force

    @status_width ||= begin
      @term_width = [%x(tput cols).to_i, 100].max
      @term_width - @padding - 10
    rescue
      100
    end

    @status_height ||= begin
      term_height = [%x(tput lines).to_i, 50].max
      term_height - 3
    rescue
      50
    end

    msg = ""

    if @banner.nil? && interfaces_group.present?
      @banner = interfaces_group.banner @status_width
      @status_height -= @banner.lines.count + 2
    end

    if @banner.present?
      msg += @banner
      msg += "\n" + "-"*@term_width + "\n"
    end

    full_status = @statuses || ""
    full_status = full_status.last(@status_width*10) || ""
    padding_size = [(@number_of_lines - @current_line - 1), (@status_width - full_status.size/10)].min
    full_status = "#{full_status}#{"."*[padding_size, 0].max}"

    msg += "#{"%#{@padding}d" % (@current_line + 1)}/#{@number_of_lines}: #{full_status}"

    lines_count = [(@status_height / 2) - 3, 1].max

    if @messages.any?
      msg += "\n\n"
      msg += colorize "=== MESSAGES (#{@messages.count}) ===\n", :green
      msg += "[...]\n" if @messages.count > lines_count
      msg += @messages.last(lines_count).map do |m|
        "[#{"%.5f" % m[0]}]\t" + m[1].truncate(@status_width - 10)
      end.join("\n")
      msg += "\n"*[lines_count-@messages.count, 0].max
    end

    if @_errors.any?
      msg += "\n\n"
      msg += colorize "=== ERRORS (#{@_errors.count}) ===\n", :red
      msg += "[...]\n" if @_errors.count > lines_count
      msg += @_errors.last(lines_count).map do |j|
        kind = j[:kind]
        kind = colorize(kind, kind == :error ? :red : :orange)
        kind = "[#{kind}]"
        kind += " "*(25 - kind.size)
        encode_string("#{kind}L#{j[:line]}\t#{j[:error]}\t\t#{j[:message]}").truncate(@status_width)
      end.join("\n")
    end
    custom_print msg, clear: true
    @last_repaint = Time.now
  end

  def custom_print msg, opts={}
    return unless @verbose
    out = ""
    msg = colorize(msg, opts[:color]) if opts[:color]
    puts "\e[H\e[2J" if opts[:clear]
    out += msg
    print out
  end

  class FailedRow < RuntimeError
  end

  class FailedOperation < RuntimeError
  end

  class Configuration
    attr_accessor :headers, :separator, :key, :context, :encoding, :ignore_failures, :scope
    attr_reader :columns

    def initialize import_name, opts={}
      @import_name = import_name
      @key = opts[:key] || "id"
      @headers = opts.has_key?(:headers) ? opts[:headers] : true
      @separator = opts[:separator] || ","
      @encoding = opts[:encoding]
      @columns = opts[:columns]&.dup || []
      @custom_handler = opts[:custom_handler]
      @before = opts[:before]
      @after = opts[:after]
      @ignore_failures = opts[:ignore_failures]
      @context = opts[:context]&.dup || {}
      @scope = opts[:scope]
    end

    def on_relation relation_name
      @current_scope ||= []
      @current_scope.push relation_name
      yield
      @current_scope.pop
    end

    def duplicate
      self.class.new @import_name, self.options
    end

    def options
      {
        key: @key,
        headers: @headers,
        separator: @separator,
        encoding: @encoding,
        columns: @columns.map(&:duplicate),
        custom_handler: @custom_handler,
        before: @before,
        after: @after,
        ignore_failures: @ignore_failures,
        context: @context,
        scope: @scope
      }
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
      @current_scope ||= []
      @columns.push Column.new({name: name.to_s, scope: @current_scope.dup}.update(opts))
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
      attr_accessor :name, :attribute
      def initialize opts={}
        @name = opts[:name]
        @options = opts
        @attribute = @options[:attribute] ||= @name
      end

      def duplicate
        Column.new @options.dup
      end

      def required?
        !!@options[:required]
      end

      def omit_nil?
        !!@options[:omit_nil]
      end

      def scope
        @options[:scope] || []
      end

      def [](key)
        @options[key]
      end
    end
  end
end
