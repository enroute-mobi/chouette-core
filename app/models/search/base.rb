module Search
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations
    extend Enumerize

    def initialize(scope, attributes = {})
      @scope = scope
      attributes["search"].each { |k, v| send "#{k}=", v } if attributes["search"]
      @page = attributes["page"] || 1
      @sort_column = attributes["sort"] || 'created_at'
      @sort_direction = attributes["direction"] || 'desc'
    end
    attr_reader :scope, :attributes, :calling_object, :sort_column, :sort_direction

    validates_numericality_of :page, greater_than_or_equal_to: 0, allow_nil: true
    validates_numericality_of :per_page, greater_than_or_equal_to: 0, allow_nil: true

    def self.model_name
      ActiveModel::Name.new(self, nil, 'Search')
    end

    def collection
      if valid?
        scope.order(order.to_hash).paginate(paginate)
      else
        scope.none
      end
    end

    def order
      @order ||= Order.new(sort_column => sort_direction)
    end

    attr_accessor :page
    attr_writer :per_page

    def per_page
      @per_page ||= 30
    end

    def paginate
      { per_page: per_page, page: page }
    end

    def self.status_group
      {
        'pending' => %w[new pending running],
        'failed' => %w[failed aborted canceled],
        'warning' => ['warning'],
        'successful' => ['successful']
      }
    end

    def find_import_statuses(values)
      return [] if values.blank?
      values.map { |value| self.class.status_group[value] }.flatten.compact
    end

    class Order

      def initialize(sort_hash)
        @sort_hash = sort_hash
      end
      attr_reader :sort_hash

      # TODO: Attributes can only return values :asc, :desc or nil (for securiy reason)
      # Attributes can be set with "asc", :asc, 1 to have the :asc value
      # Attributes can be set with "desc", :desc, -1 to have the :desc value
      # Attributes can be set with nil, 0 to have the nil value
      #
      # These methods ensures that the sort attribute is supported and valid
      def to_hash
        sort_hash.delete_if { |_, v| v.nil? }
      end
    end
  end
end
