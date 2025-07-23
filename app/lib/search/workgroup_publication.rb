# frozen_string_literal: true

module Search
  class WorkgroupPublication < ::Search::Operation
    attr_accessor :workgroup

    def searched_class
      ::Publication
    end

    def query_class
      Query::WorkgroupPublication
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
          ::Publication.status.values
        end

        def label(key)
          I18n.t(key, scope: 'publications.statuses')
        end
      end
      group_by_attribute 'creator', :string

      aggregate_attribute 'duration', 'EXTRACT(EPOCH FROM ended_at - started_at)'
    end
  end
end
