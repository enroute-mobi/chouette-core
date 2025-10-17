# frozen_string_literal: true

module Search
  class Merge < ::Search::Operation
    attr_accessor :workbench

    attribute :text

    def searched_class
      ::Merge
    end

    def query_class
      Query::Merge
    end

    def query(scope)
      query_class.new(scope).workbenches(workbenches).text(text).user_statuses(statuses).in_period(period)
    end

    class Order < ::Search::Order
      attribute :created_at, default: :desc
      attribute :statuses
      attribute :name
      attribute :creator
    end
  end
end
