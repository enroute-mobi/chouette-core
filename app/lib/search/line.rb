module Search
  class Line < Base
		extend Enumerize

    # All search attributes
    attribute :text
    attribute :network_id
    attribute :company_id
    attribute :line_provider_id
    attribute :transport_mode
    attribute :statuses
		attribute :valid_after_date, type: Date
    attribute :valid_before_date, type: Date
		attribute :is_referent

    enumerize :transport_mode, in: TransportModeEnumerations.transport_modes, multiple: true
		enumerize :statuses, in: ::Chouette::Line.statuses, i18n_scope: 'lines.statuses'

    attr_accessor :workbench
    delegate :line_referential, to: :workbench

		def period
      Period.new(from: valid_before_date, to: valid_after_date).presence
    end

    validates :period, valid: true

    def query(scope)
			Query::Line.new(scope)
				.text(text)
				.network_id(network_id)
				.company_id(company_id)
				.line_provider_id(line_provider_id)
				.transport_mode(transport_mode)
				.statuses(statuses)
				.in_period(period)
				.is_referent(is_referent)
    end

		def is_referent
			flag(super)
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

		def flag(value)
			ActiveModel::Type::Boolean.new.cast(value)
		end

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :number
      attribute :registration_number
      attribute :deactivated
      attribute :transport_mode
      attribute :transport_submode
			attribute :company, joins: :company, column: 'companies.name'
    	attribute :network, joins: :network, column: 'networks.name'
    end
  end
end
