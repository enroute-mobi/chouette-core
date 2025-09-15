module Search
  class Operation < Base
    # All search attributes
    attribute :name
    attribute :workbench_ids
    attribute :statuses
    attribute :start_date, type: Date
    attribute :end_date, type: Date

    period :period, :start_date, :end_date, chart_attributes: %i[started_at ended_at]

    def candidate_statuses
      ::Operation::UserStatus.all
    end

    attr_accessor :workgroup

    def candidate_workbenches
      workgroup&.workbenches || Workbench.none
    end

    def workbenches
      candidate_workbenches.where(id: workbench_ids)
    end

    def query(scope)
      query_class.new(scope).workbenches(workbenches).text(name).user_statuses(statuses).in_period(period)
    end

    def query_class
      raise "Not yet implemented"
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
      group_by_attribute 'started_at', :datetime, sub_types: %i[hour_of_day day_of_week]
      group_by_attribute 'user_status', :string do
        def keys
          ::Operation.user_status.values
        end

        def label(key)
          ::Operation.user_status.find_value(key).text
        end
      end
      group_by_attribute 'creator', :string

      aggregate_attribute 'duration', 'EXTRACT(EPOCH FROM ended_at - started_at)'
    end
  end
end
