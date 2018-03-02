class SimpleExporter < SimpleInterface
  def export opts={}
    configuration.validate!
    @verbose = opts.delete :verbose

    @resolution_queue = Hash.new{|h,k| h[k] = []}
    @errors = []
    @messages = []
    @number_of_lines = 0
    @padding = 1
    @current_line = -1
    @number_of_lines = collection.size
    @padding = [1, Math.log(@number_of_lines, 10).ceil()].max

    @csv = nil
    fail_with_error "Unable to write in file: #{self.filepath}" do
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
  def process_collection
    self.configuration.before_actions(:all).each do |action| action.call self end
    log "Starting export ...", color: :green
    log "Export will be written in #{filepath}", color: :green
    @csv << self.configuration.columns.map(&:name)
    ids = collection.pluck :id
    ids.in_groups_of(configuration.batch_size).each do |batch_ids|
      collection.where(id: batch_ids).each do |item|
        @current_row = item.attributes
        @current_row = @current_row.slice(*configuration.logged_attributes) if configuration.logged_attributes.present?
        row = []
        @new_status = nil
        self.configuration.columns.each do |col|
          val = col[:value]
          if val.nil? || val.is_a?(Proc)
            if item.respond_to? col.attribute
              if val.is_a?(Proc)
                val = instance_exec(item.send(col.attribute), &val)
              else
                val = item.send(col.attribute)
              end
            else
              push_in_journal({event: :attribute_not_found, message: "Attribute not found: #{col.attribute}", kind: :warning})
              self.status ||= :success_with_warnings
            end
          end

          if val.nil? && col.required?
            @new_status = colorize("x", :red)
            raise "MISSING VALUE FOR COLUMN #{col.name}"
          end
          @new_status ||= colorize("✓", :green)
          val = encode_string(val) if val.is_a?(String)
          row << val
        end
        push_in_journal({event: :success, kind: :log})
        @statuses += @new_status
        print_state if @current_line % 20 == 0
        @current_line += 1
        @csv << row
      end
    end
    print_state
  end

  class Configuration < SimpleInterface::Configuration
    attr_accessor :collection
    attr_accessor :batch_size
    attr_accessor :logged_attributes

    def initialize import_name, opts={}
      super import_name, opts
      @collection = opts[:collection]
      @batch_size = opts[:batch_size] || 1000
      @logged_attributes = opts[:logged_attributes]
    end

    def options
      super.update({
        collection: collection,
        batch_size: batch_size,
        logged_attributes: logged_attributes,
      })
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
