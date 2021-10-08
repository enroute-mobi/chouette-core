module Search
  class Operation < Base
    # All search attributes
    attribute :name
    attribute :workbench_ids
    attribute :statuses
    attribute :start_date, type: Date
    attribute :end_date, type: Date

    def candidate_statuses
      ::Operation::UserStatus.all
    end

    def period
      Period.new(from: start_date, to: end_date).presence
    end

    validates :period, valid: true

    attr_accessor :workgroup

    def candidate_workbenches
      workgroup&.workbenches || Workbench.none
    end

    def workbenches
      candidate_workbenches.where(id: workbench_ids)
    end

    def query
      query_class.new(scope).workbenches(workbenches).text(name).user_statuses(statuses).in_period(period)
    end

    def query_class
      raise "Not yet implemented"
    end

    class Order < ::Search::Order
      attribute :status
      attribute :name
      attribute :started_at
      attribute :creator
    end
  end
end
