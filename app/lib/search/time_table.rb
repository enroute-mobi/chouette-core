module Search
  class TimeTable < Base
    attr_accessor :workbench

    attribute :comment
    attribute :start_date, type: Date
    attribute :end_date, type: Date

    period :period, :start_date, :end_date

    def query(scope)
      Query::TimeTable.new(scope).comment(comment).in_period(period)
    end

    class Order < ::Search::Order
      attribute :comment, default: :asc
    end
  end
end
