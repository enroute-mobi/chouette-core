module Search
  class Line < Base
		extend Enumerize

    # All search attributes
    attribute :text
    attribute :network_id
    attribute :company_id
    attribute :line_provider_id
    attribute :transport_mode
    attribute :line_status
		attribute :valid_after_date, type: Date
    attribute :valid_before_date, type: Date

    enumerize :transport_mode, in: TransportModeEnumerations.transport_modes, multiple: true
		enumerize :line_status, in: ::Chouette::Line.statuses

		attr_accessor :line_referential

		def period
      Period.new(from: valid_before_date, to: valid_after_date).presence
    end

    validates :period, valid: true

    def query
			Query::Line.new(scope)
				.text(text)
				.network_id(network_id)
				.company_id(company_id)
				.line_provider_id(line_provider_id)
				.transport_mode(transport_mode)
				.line_status(line_status)
				.in_period(period)
    end

		def candidate_networks
			line_referential.networks.order(Arel.sql('lower(name) asc'))
		end

		def candidate_line_providers
			line_referential.line_providers
		end

		def candidate_companies
			line_referential.companies
		end

		def candidate_parents
			line_referential.lines
		end

		private

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :registration_number
    end
  end
end
