# frozen_string_literal: true

module Search
  class StopAreaRoutingConstraint < Base
    # All search attributes
    attribute :text
    attribute :both_way

    attr_accessor :workbench

    def searched_class
      ::StopAreaRoutingConstraint
    end

    def query(scope)
      Query::StopAreaRoutingConstraint.new(scope) \
                                      .text(text) \
                                      .both_way(both_way)
    end

    class Order < ::Search::Order
      # TODO: CHOUETTE-4721 (rails 7.2): we may have to simply do scope.order(order_hash) in Search::Base with:
      # attribute :from, joins: :from, column: { from: { name: :asc } }
      attribute :from, joins: :from, column: 'from.name', default: :asc
      attribute :to, joins: :to, column: 'to.name'
      attribute :both_way
    end
  end
end
