# frozen_string_literal: true

module Search
  class ConnectionLink < Base
    # All search attributes
    attribute :text

    attr_accessor :workbench

    def searched_class
      ::Chouette::ConnectionLink
    end

    def query(scope)
      Query::ConnectionLink.new(scope) \
                           .text(text)
    end

    class Order < ::Search::Order
      attribute :departure, joins: :departure, column: 'departure.name', default: :desc
      attribute :arrival, joins: :arrival, column: 'arrival.name'
    end
  end
end
