# frozen_string_literal: true

module Search
  class AbstractExport < ::Search::Operation
    def searched_class
      ::Export::Base
    end

    def query_class
      Query::Export
    end

    class Order < ::Search::Operation::Order
      attribute :type
      attribute :referential, joins: :referential, column: 'referentials.name'
    end

    class Chart < ::Search::Operation::Chart
      group_by_attributes.delete('user_status')
      group_by_attributes.delete('creator')

      group_by_attribute 'status', :string do
        def keys
          ::Export::Base.status.values
        end

        def label(key)
          I18n.t(key, scope: 'exports.status')
        end
      end
    end
  end
end
