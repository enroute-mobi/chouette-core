# frozen_string_literal: true

module Search
  class WorkgroupAggregate < ::Search::Operation
    attr_accessor :workgroup

    attribute :text

    def searched_class
      ::Aggregate
    end

    def query_class
      Query::WorkgroupAggregate
    end

    def query(scope)
      query_class.new(scope).workbenches(workbenches).text(text).user_statuses(statuses).in_period(period)
    end

    class Order < ::Search::Order
      attribute :statuses
      attribute :name
      attribute :started_at, default: :desc
      attribute :creator
    end

    class Chart < ::Search::Operation::Chart
      group_by_attributes.delete('user_status')

      group_by_attribute 'status', :string do
        def keys
          ::Aggregate.status.values
        end

        def label(key)
          I18n.t(key, scope: 'aggregates.statuses')
        end
      end
    end
  end
end
