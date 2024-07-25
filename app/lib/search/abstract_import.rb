# frozen_string_literal: true

module Search
  class AbstractImport < ::Search::Operation
    AUTHORIZED_GROUP_BY_ATTRIBUTES = (superclass::AUTHORIZED_GROUP_BY_ATTRIBUTES + %w[status]).freeze

    NUMERIC_ATTRIBUTES = {
      'duration' => 'EXTRACT(EPOCH FROM ended_at - started_at)'
    }.freeze

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
      private

      def all_status_keys
        ::Import::Base.status.values
      end

      def label_status_key(key)
        I18n.t(key, scope: 'imports.status')
      end
    end
  end
end
