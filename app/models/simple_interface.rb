class SimpleInterface < ApplicationModel
  include PrettyOutput

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

    init_output
    @current_line = -1
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
      Chouette::Safe.capture "#{self.class.name} ##{id} failed", e

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
