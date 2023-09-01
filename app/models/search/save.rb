# frozen_string_literal: true

module Search
  class Save < ApplicationModel
    self.table_name = 'saved_searches'

    belongs_to :workbench, class_name: '::Workbench', optional: false
    validates :name, :search_type, presence: true

    def self.for(search_type)
      where(search_type: search_type.to_s)
    end

    def search(context = {})
      all_attributes = search_attributes.merge(context).merge(id: id, name: name, description: description)
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
