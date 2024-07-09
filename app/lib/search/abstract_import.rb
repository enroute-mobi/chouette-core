# frozen_string_literal: true

module Search
  class AbstractImport < ::Search::Operation
    AUTHORIZED_GROUP_BY_ATTRIBUTES = (superclass::AUTHORIZED_GROUP_BY_ATTRIBUTES + %w[status]).freeze

    def query_class
      Query::Import
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
