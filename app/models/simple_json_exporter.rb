class SimpleJsonExporter < SimpleExporter

  def export opts={}
    configuration.validate!

    init_env opts

    if self.configuration.root
      @out = {self.configuration.root => []}
    else
      @out = []
    end

    fail_with_error "Unable to write in file: #{self.filepath}" do
      dir = Pathname.new(self.filepath).dirname
      FileUtils.mkdir_p dir
      @file = File.open(self.filepath, 'w', self.configuration.file_options)
    end

    self.configuration.before_actions(:parsing).each do |action| action.call self end

    @statuses = ""

    if ENV["NO_TRANSACTION"]
      process_collection
    else
      ActiveRecord::Base.transaction do
        process_collection
      end
    end
    self.status ||= :success
  rescue SimpleInterface::FailedOperation
    self.status = :failed
  ensure
    if @file
      @file.write @out.to_json
      @file.close
    end
    self.save!
  end

  protected
  def root
    if self.configuration.root
      @out[self.configuration.root]
    else
      @out
    end
  end

  def process_collection
    self.configuration.before_actions(:all).each do |action| action.call self end
    log "Starting export ...", color: :green
    log "Export will be written in #{filepath}", color: :green

    if collection.is_a?(ActiveRecord::Relation) && collection.model.column_names.include?("id")
      ids = collection.pluck :id
      ids.in_groups_of(configuration.batch_size).each do |batch_ids|
        collection.where(id: batch_ids).each do |item|
          handle_item item
        end
      end
    else
      collection.each{|item| handle_item item }
    end
    print_state
  end

  def resolve_node item, node
    vals = []
    scoped_item = node.scope.inject(item){|tmp, scope| tmp.send(scope)}

    [scoped_item.send(node.attribute)].flatten.each do |node_item|
      item_val = {}
      apply_configuration node_item, node.configuration, item_val
      vals.push item_val
    end
    node.multiple ? vals : vals.first
  end

  def apply_configuration item, configuration, output
    configuration.columns.each do |col|
      val = resolve_value item, col
      output[col.name] = val unless val.nil? && col.omit_nil?
    end

    configuration.nodes.each do |node|
      val = resolve_node item, node
      output[node.name] = val
    end
  end

  def handle_item item
    number_of_lines = @number_of_lines
    @current_item = item
    map_item_to_rows(item).each_with_index do |item, i|
      @number_of_lines = number_of_lines + i
      serialized_item = {}
      @current_row = item.attributes
      @current_row = @current_row.slice(*configuration.logged_attributes) if configuration.logged_attributes.present?
      @new_status = nil

      apply_configuration item, self.configuration, serialized_item

      @new_status ||= colorize("✓", :green)

      push_in_journal({event: :success, kind: :log})
      @statuses += @new_status
      print_state if @current_line % 20 == 0 || i > 0
      @current_line += 1
      append_item serialized_item
    end
  end

  def append_item serialized_item
    root.push serialized_item
  end

  class Configuration < SimpleExporter::Configuration
    attr_reader :nodes
    attr_accessor :root

    alias_method :add_field, :add_column

    def initialize import_name, opts={}
      super import_name, opts
      @collection = opts[:collection]
      @nodes = opts[:nodes] || []
      @root = opts[:root]
    end

    def options
      super.update({
        nodes: @nodes,
        root: @root,
      })
    end

    def add_node name, opts={}
      @nodes ||= []
      @current_scope ||= []
      node = Node.new({name: name.to_s, scope: @current_scope.dup}.update(opts))
      yield node.configuration
      @nodes.push node
    end

    def add_nodes name, opts={}, &block
      self.add_node name, opts.update({multiple: true}), &block
    end

    def file_options
      {
        encoding: self.encoding
      }
    end
  end

  class NodeConfiguration < Configuration
    def initialize node
      super
    end
  end

  class Node
    attr_accessor :name, :configuration

    def initialize opts={}
      @name = opts[:name]
      @options = opts
      @configuration = NodeConfiguration.new self
    end

    def attribute
      @options[:attribute] || name
    end

    def multiple
      !!@options[:multiple]
    end

    def scope
      @options[:scope] || []
    end
  end
end
