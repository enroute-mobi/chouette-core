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
  end
end
