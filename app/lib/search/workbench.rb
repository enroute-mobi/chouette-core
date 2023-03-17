module Search
  class Workbench < Base
		attr_accessor :workbench
    attr_accessor :user

		extend Enumerize

    # All search attributes
    attribute :text
    attribute :line
    attribute :states
    attribute :workbench_id
		# attribute :valid_after_date, type: Date
    # attribute :valid_before_date, type: Date

    # enumerize :transport_mode, in: TransportModeEnumerations.transport_modes, multiple: true
		enumerize :states, in: Referential.states, multiple: true

		# def period
    #   Period.new(from: valid_before_date, to: valid_after_date).presence
    # end

    # validates :period, valid: true

    def query
			Query::Workbench.new(scope)
				.text(text)
				.line(line)
				.states(states)
				.workbench_id(workbench_id)
				# .in_period(period)
    end

    def candidate_lines
      workbench.lines.order(:name)
    end

    def candidate_workbenches
      user.workbenches.order(:name)
    end

		private

    class Order < ::Search::Order
      attribute :name, default: :asc
      # attribute :number
			# attribute :company, joins: :company, column: 'companies.name'
    	# attribute :network, joins: :network, column: 'networks.name'
    end
  end
end
