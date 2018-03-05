class SimpleExporter < SimpleInterface
  def export opts={}
    configuration.validate!

    init_env opts

    @csv = nil
    fail_with_error "Unable to write in file: #{self.filepath}" do
      dir = Pathname.new(self.filepath).dirname
      FileUtils.mkdir_p dir
      @csv = CSV.open(self.filepath, 'w', self.configuration.csv_options)
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
    @csv&.close
    self.save!
  end

  def collection
    @collection ||= begin
      coll = configuration.collection
      coll = coll.call() if coll.is_a?(Proc)
      coll
    end
  end

  def encode_string s
    s.encode("utf-8").force_encoding("utf-8")
  end

  protected
  def init_env opts
    @number_of_lines = collection.size

    super opts
  end

  def process_collection
    self.configuration.before_actions(:all).each do |action| action.call self end
    log "Starting export ...", color: :green
    log "Export will be written in #{filepath}", color: :green
    @csv << self.configuration.columns.map(&:name)
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

  def map_item_to_rows item
    return [item] unless configuration.item_to_rows_mapping
    configuration.item_to_rows_mapping.call(item).map {|row| row.is_a?(ActiveRecord::Base) ? row : CustomRow.new(row) }
  end

  def resolve_value item, col
    scoped_item = col.scope.inject(item){|tmp, scope| tmp.send(scope)}
    val = col[:value]
    if val.nil? || val.is_a?(Proc)
      if val.is_a?(Proc)
        val = instance_exec(scoped_item, &val)
      else
        attributes = [col.attribute].flatten
        val = attributes.inject(scoped_item){|tmp, attr| tmp.send(attr)}
      end
    end
    if val.nil? && !col.omit_nil?
      push_in_journal({event: :attribute_not_found, message: "Value missing for: #{[col.scope, col.attribute].flatten.join('.')}", kind: :warning})
      self.status ||= :success_with_warnings
    end

    if val.nil? && col.required?
      @new_status = colorize("x", :red)
      raise "MISSING VALUE FOR COLUMN #{col.name}"
    end

    val = encode_string(val) if val.is_a?(String)
    val
  end

  def handle_item item
    number_of_lines = @number_of_lines
    @current_item = item
    map_item_to_rows(item).each_with_index do |item, i|
      @number_of_lines = number_of_lines + i
      @current_row = item.attributes
      @current_row = @current_row.slice(*configuration.logged_attributes) if configuration.logged_attributes.present?
      row = []
      @new_status = nil
      self.configuration.columns.each do |col|
        val = resolve_value item, col
        @new_status ||= colorize("✓", :green)
        row << val
      end
      push_in_journal({event: :success, kind: :log})
      @statuses += @new_status
      print_state if @current_line % 20 == 0 || i > 0
      @current_line += 1
      @csv << row
    end
  end

  class CustomRow < OpenStruct
    def initialize data
      super data
      @data = data
    end

    def attributes
      flatten_hash @data
    end

    protected
    def flatten_hash h
      h.each_with_object({}) do |(k, v), h|
        if v.is_a? Hash
          flatten_hash(v).map do |h_k, h_v|
            h["#{k}.#{h_k}".to_sym] = h_v
          end
        else
          h[k] = v
        end
      end
    end
  end

  class Configuration < SimpleInterface::Configuration
    attr_accessor :collection
    attr_accessor :batch_size
    attr_accessor :logged_attributes
    attr_accessor :item_to_rows_mapping

    def initialize import_name, opts={}
      super import_name, opts
      @collection = opts[:collection]
      @batch_size = opts[:batch_size] || 1000
      @logged_attributes = opts[:logged_attributes]
      @item_to_rows_mapping = opts[:item_to_rows_mapping]
    end

    def options
      super.update({
        collection: collection,
        batch_size: batch_size,
        logged_attributes: logged_attributes,
        item_to_rows_mapping: item_to_rows_mapping,
      })
    end

    def map_item_to_rows &block
      @item_to_rows_mapping = block
    end

    def add_column name, opts={}
      raise "Column already defined: #{name}" if @columns.any?{|c| c.name == name.to_s}
      super name, opts
    end

    def validate!
      raise "Incomplete configuration, missing collection for #{@import_name}" if collection.nil?
    end
  end
end
