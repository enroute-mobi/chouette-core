class SimpleInterface < ActiveRecord::Base
  attr_accessor :configuration

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
      raise "Importer not found: #{name}" unless configuration
      configuration
    end
  end

  def initialize *args
    super *args
    self.configuration = self.class.find_configuration self.configuration_name
    self.journal ||= []
  end

  def init_env opts
    @verbose = opts.delete :verbose

    @errors = []
    @messages = []
    @padding = 1
    @current_line = 0
    @padding = [1, Math.log([@number_of_lines, 1].max, 10).ceil()].max
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
    if opts[:append]
      @messages[-1] = (@messages[-1] || "") + msg
    else
      @messages << msg
    end
    print_state
  end

  protected

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
      msg += @messages.last(lines_count).map{|m| m.truncate(@status_width)}.join("\n")
      msg += "\n"*[lines_count-@messages.count, 0].max
    end

    if @errors.any?
      msg += "\n\n"
      msg += colorize "=== ERRORS (#{@errors.count}) ===\n", :red
      msg += "[...]\n" if @errors.count > lines_count
      msg += @errors.last(lines_count).map do |j|
        kind = j[:kind]
        kind = colorize(kind, kind == :error ? :red : :orange)
        kind = "[#{kind}]"
        kind += " "*(25 - kind.size)
        encode_string("#{kind}L#{j[:line]}\t#{j[:error]}\t\t#{j[:message]}").truncate(@status_width)
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
      @columns = opts[:columns] || []
      @custom_handler = opts[:custom_handler]
      @before = opts[:before]
      @after = opts[:after]
      @ignore_failures = opts[:ignore_failures]
      @context = opts[:context] || {}
      @scope = opts[:scope]
    end

    def on_relation relation_name
      @scope ||= []
      @scope.push relation_name
      yield
      @scope.pop
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
      @scope ||= []
      @columns.push Column.new({name: name.to_s, scope: @scope.dup}.update(opts))
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

      def scope
        @options[:scope] || []
      end

      def [](key)
        @options[key]
      end
    end
  end
end
