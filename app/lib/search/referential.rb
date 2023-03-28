module Search
  class Referential < Base
    attr_accessor :workbench

    delegate :workgroup, to: :workbench

    extend Enumerize

    # All search attributes
    attribute :text
    attribute :line
    attribute :statuses
    attribute :workbench_ids
    attribute :valid_after_date, type: Date
    attribute :valid_before_date, type: Date

    enumerize :statuses, in: ::Referential::STATES, multiple: true, i18n_scope: 'referentials.states'

    def period
      Period.new(from: valid_before_date, to: valid_after_date).presence
    end

    validates :period, valid: true

    def query
      Query::Referential.new(scope)
                        .text(text)
                        .line(line)
                        .statuses(statuses)
                        .workbenches(workbench_ids)
                        .in_period(period)
    end

    def candidate_lines
      workbench.lines.order(:name)
    end

    def candidate_workbenches
      workgroup.workbenches.order(:name)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
      # attribute :status
      attribute :workbench, joins: :workbench, column: 'workbenches.name'
      attribute :created_at
      attribute :merged_at
    end
  end
end
