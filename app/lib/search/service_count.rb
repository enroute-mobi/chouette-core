# frozen_string_literal: true

module Search
  class ServiceCount < Base
    # All search attributes
    attribute :line_ids
    attribute :company_ids
    attribute :network_ids
    attribute :transport_modes
    attribute :start_date, type: Date
    attribute :end_date, type: Date
    attribute :days_of_week, type: Cuckoo::DaysOfWeek::Type.new,
                             typecaster: Cuckoo::DaysOfWeek::Type.new,
                             default: Cuckoo::DaysOfWeek.all

    enumerize :transport_modes, in: TransportModeEnumerations.transport_modes, multiple: true

    period :period, :start_date, :end_date, chart_attributes: %i[date]

    attr_accessor :workbench

    def searched_class
      ::ServiceCount
    end

    def query(scope)
      Query::ServiceCount.new(scope) \
                         .line_ids(lines) \
                         .company_ids(companies) \
                         .network_ids(networks) \
                         .transport_modes(transport_modes) \
                         .in_period(period) \
                         .days_of_week(days_of_week)
    end

    def candidate_lines
      workbench.lines
    end

    def lines
      candidate_lines.where(id: line_ids)
    end

    def candidate_companies
      workbench.companies.order(:name)
    end

    def companies
      candidate_companies.where(id: company_ids)
    end

    def candidate_networks
      workbench.networks.order(:name)
    end

    def networks
      candidate_networks.where(id: network_ids)
    end

    class Order < ::Search::Order
      attribute :date, default: :asc
    end

    class Chart < ::Search::Base::Chart
      group_by_attribute 'date', :date, sub_types: %i[by_week by_month day_of_week]
      group_by_attribute 'line_id', :string, joins: { line: {} }, selects: %w[lines.name]
      group_by_attribute 'company_id', :string, joins: { line: { company: {} } }, selects: %w[companies.name]
      group_by_attribute 'network_id', :string, joins: { line: { network: {} } }, selects: %w[networks.name]
      group_by_attribute 'transport_mode', :string, joins: { line: {} }, selects: %w[lines.transport_mode] do
        def keys
          @keys ||= Chouette::TransportMode.mode_candidates.map(&:to_s)
        end

        def label(key)
          Chouette::TransportMode.new(key).mode_human_name
        end
      end
      group_by_attribute 'route_wayback', :string, joins: { route: {} }, selects: %w[routes.wayback] do
        def keys
          Chouette::Route.wayback.values
        end

        def label(key)
          Chouette::Route.wayback.find_value(key).text
        end
      end

      private

      def count_column_name
        column_alias(:sum, :count)
      end

      def aggregate_count(request)
        request.sum(:count)
      end
    end
  end
end
