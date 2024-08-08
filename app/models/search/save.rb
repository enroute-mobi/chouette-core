# frozen_string_literal: true

module Search
  class Save < ApplicationModel
    self.table_name = 'saved_searches'

    belongs_to :parent, polymorphic: true, optional: false
    validates :name, :search_type, presence: true

    class << self
      # rubocop:disable Naming/MemoizedInstanceVariableName
      def model_name
        @_model_name ||= ActiveModel::Name.new(self, nil).tap do |name|
          name.instance_variable_set(:@singular_route_key, 'search')
          name.instance_variable_set(:@route_key, 'searches')
        end
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName

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

    def used(now = Time.zone.now)
      if persisted?
        update_column :last_used_at, now # rubocop:disable Rails/SkipsModelValidations
      else
        self.last_used_at = now
      end
    end
  end
end
