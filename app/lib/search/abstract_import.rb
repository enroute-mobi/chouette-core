# frozen_string_literal: true

module Search
  class AbstractImport < ::Search::Operation
    def searched_class
      ::Import::Base
    end

    def query_class
      Query::Import
    end

    class Order < ::Search::Order
      # Use for Macro::List::Run and Control::List::Run
      attribute :user_status
      # Use for Import and Export classes and should migrate to user_status
      attribute :status
      attribute :name
      attribute :started_at, default: :desc
      attribute :creator
    end

    class Chart < ::Search::Base::Chart
      group_by_attribute 'status', :string do
        def keys
          ::Import::Base.status.values
        end

        def label(key)
          I18n.t(key, scope: 'imports.status')
        end
      end

      aggregate_attribute 'duration', 'EXTRACT(EPOCH FROM ended_at - started_at)'
    end
  end
end
