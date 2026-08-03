# frozen_string_literal: true

module Search
  class Save < ApplicationModel
    self.table_name = 'saved_searches'

    REFERENTIAL_SEARCH_TYPES = %w[
      Search::ServiceCount
    ].freeze

    belongs_to :parent, polymorphic: true # CHOUETTE-3247 optional: false
    validates :name, presence: true, uniqueness: { scope: %i[parent_type parent_id search_type] }
    validates :search_type, presence: true

    scope :by_text, ->(text) { text.blank? ? all : where('lower(name) LIKE :t', t: "%#{text.downcase}%") }
    scope :graphical, -> { where(%(#{quoted_table_name}."search_attributes" ->> 'chart_type' IS NOT NULL)) }
    scope :non_graphical, -> { where(%(#{quoted_table_name}."search_attributes" ->> 'chart_type' IS NULL)) }
    scope :referential, -> { where(search_type: REFERENTIAL_SEARCH_TYPES) }
    scope :non_referential, -> { where.not(search_type: REFERENTIAL_SEARCH_TYPES) }

    class << self
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def model_name
        @_model_name ||= ActiveModel::Name.new(self, nil).tap do |name|
          name.instance_variable_set(:@singular_route_key, 'search')
          name.instance_variable_set(:@route_key, 'searches')
        end
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

      def search_class_name(parent, resource_name)
        "Search::#{'Workgroup' if parent.is_a?(::Workgroup)}#{resource_name.classify}"
      end

      def for(search_type)
        where(search_type: search_type.to_s)
      end
    end

    def search(context = {})
      all_attributes = search_attributes.merge(context)
      all_attributes[:saved_search] = self
      all_attributes[parent_type.underscore.to_sym] = parent

      search_class.new(all_attributes).tap do
        used
      end
    end

    def search_class
      search_type.constantize
    end

    def searched_class
      search_class.new.searched_class
    end

    def resource_name
      result = search_type.demodulize.underscore.pluralize
      result = result['workgroup_'.length..] if parent.is_a?(::Workgroup)
      result
    end

    def used(now = Time.zone.now)
      if persisted?
        update_column :last_used_at, now # rubocop:disable Rails/SkipsModelValidations
      else
        self.last_used_at = now
      end
    end
  end
end
