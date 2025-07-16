# frozen_string_literal: true

module Search
  class WorkgroupAggregate < ::Search::Operation
    attr_accessor :workgroup

    def searched_class
      ::Aggregate
    end

    def query_class
      Query::WorkgroupAggregate
    end

    class Order < ::Search::Order
      attribute :statuses
      attribute :name
      attribute :started_at, default: :desc
      attribute :creator
    end

    class Chart < ::Search::Base::Chart
      group_by_attribute 'started_at', :datetime, sub_types: %i[hour_of_day day_of_week]
      group_by_attribute 'status', :string do
        def keys
          ::Aggregate.status.values
        end

        def label(key)
          I18n.t(key, scope: 'aggregates.statuses')
        end
      end

      aggregate_attribute 'duration', 'EXTRACT(EPOCH FROM ended_at - started_at)'
      group_by_attribute 'creator', :string
    end
  end
end
