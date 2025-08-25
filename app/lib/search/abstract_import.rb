# frozen_string_literal: true

module Search
  class AbstractImport < ::Search::Operation
    def searched_class
      ::Import::Base
    end

    def query_class
      Query::Import
    end

    class Chart < ::Search::Operation::Chart
      group_by_attributes.delete('user_status')
      group_by_attributes.delete('creator')

      group_by_attribute 'status', :string do
        def keys
          ::Import::Base.status.values
        end

        def label(key)
          I18n.t(key, scope: 'imports.status')
        end
      end
    end
  end
end
