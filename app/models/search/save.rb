module Search
  class Save < ApplicationModel
    self.table_name = 'saved_searches'

    belongs_to :workbench, class_name: '::Workbench'

    def self.for(search_type)
      where(search_type: search_type.to_s)
    end

    def search(scope, context = {})
      new_search = search_type.classify.constantize.new(
        scope,
        { search: search_attributes.merge(search_id: id) },
        context
      )
      
      used
      new_search
    end

    def used(now = Time.zone.now)
      if persisted?
        update_column :last_used_at, now
      else
        self.last_used_at = now
      end
    end
  end
end