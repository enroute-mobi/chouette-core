module Search
  class Workbench < Base
		attr_accessor :workbench
		attr_accessor :line_referential
		extend Enumerize

    # All search attributes
    attribute :text
    attribute :line
    # attribute :status
    # attribute :workbench
		attribute :valid_after_date, type: Date
    attribute :valid_before_date, type: Date

    # enumerize :transport_mode, in: TransportModeEnumerations.transport_modes, multiple: true
		# enumerize :line_status, in: ::Chouette::Line.statuses

		def period
      Period.new(from: valid_before_date, to: valid_after_date).presence
    end

    # validates :period, valid: true

    def query
			Query::Workbench.new(scope)
				.text(text)
				.line(line)
				.in_period(period)
				# .status(status)
				# .workbench(workbench)
    end

    def candidate_lines
      workbench.line_referential.lines.order(:name)
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
