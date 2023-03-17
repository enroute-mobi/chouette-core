module Search
  class Workbench < Base
		attr_accessor :workbench

    delegate :workgroup, to: :workbench

		extend Enumerize

    # All search attributes
    attribute :text
    attribute :line
    attribute :states
    attribute :workbench_id
		attribute :valid_after_date, type: Date
    attribute :valid_before_date, type: Date

		enumerize :states, in: Referential.states, multiple: true

		def period
      Period.new(from: valid_before_date, to: valid_after_date).presence
    end

    validates :period, valid: true

    def query
			Query::Workbench.new(scope)
				.text(text)
				.line(line)
				.states(states)
				.workbench_id(workbench_id)
				.in_period(period)
    end

    def candidate_lines
      workbench.lines.order(:name)
    end

    def candidate_workbenches
      workgroup.workbenches.order(:name)
    end

		private

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :states
    	attribute :workbench, joins: :workbench, column: 'workbenches.name'
    end
  end
end
