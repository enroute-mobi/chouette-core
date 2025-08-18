# frozen_string_literal: true

module Search
  class VehicleJourney < Base
    attr_accessor :referential

    attribute :text
    attribute :journey_pattern_id
    attribute :company_id
    attribute :line_id
    attribute :time_table_id
    attribute :with_time_table, type: Boolean
    attribute :start_date, type: Date
    attribute :end_date, type: Date
    attribute :from_stop_area_id
    attribute :to_stop_area_id
    attribute :departure_time_start
    attribute :departure_time_end
    attribute :departure_time_allow_empty, type: Boolean

    period :period, :start_date, :end_date

    validates :start_date, presence: true, if: proc { |search| search.end_date.present? }
    validates :end_date, presence: true, if: proc { |search| search.start_date.present? }
    validates :departure_time_start, presence: true, if: ->(search) { search.departure_time_end.present? }
    validates :departure_time_end, presence: true, if: ->(search) { search.departure_time_start.present? }
    validates :journey_pattern, inclusion: { in: ->(search) { search.candidate_journey_patterns } }, allow_blank: true
    validates :company, inclusion: { in: ->(search) { search.candidate_companies } }, allow_blank: true, allow_nil: true
    validates :line, inclusion: { in: ->(search) { search.candidate_lines } }, allow_blank: true, allow_nil: true
    validates :time_table, inclusion: { in: ->(search) { search.candidate_time_tables } }, allow_blank: true, allow_nil: true
    validates :from_stop_area, inclusion: { in: lambda { |search|
                                                  search.candidate_stop_areas
                                                } }, allow_blank: true, allow_nil: true
    validates :to_stop_area, inclusion: { in: lambda { |search|
                                                search.candidate_stop_areas
                                              } }, allow_blank: true, allow_nil: true

    def searched_class
      ::Chouette::VehicleJourney
    end

    def company
      referential.companies.find(company_id) if company_id.present?
    end

    def line
      referential.lines.find(line_id) if line_id.present?
    end

    def time_table
      referential.time_tables.find(time_table_id) if time_table_id.present?
    end

    def from_stop_area
      referential.stop_areas.find(from_stop_area_id) if from_stop_area_id.present?
    end

    def selected_from_stop_area_collection
      [from_stop_area].compact
    end

    def to_stop_area
      referential.stop_areas.find(to_stop_area_id) if to_stop_area_id.present?
    end

    def selected_to_stop_area_collection
      [to_stop_area].compact
    end

    def selected_time_table_collection
      [time_table].compact
    end

    def candidate_journey_patterns
      referential.journey_patterns
    end

    def candidate_lines
      referential.lines.order(:name)
    end

    def candidate_companies
      referential.companies.order(:name)
    end

    def candidate_time_tables
      referential.time_tables
    end

    def candidate_stop_areas
      referential.stop_areas
    end

    def query(scope) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      Query::VehicleJourney.new(scope) \
                           .text(text) \
                           .journey_pattern_id(journey_pattern_id) \
                           .company(company) \
                           .line(line) \
                           .time_table(time_table) \
                           .with_time_table(with_time_table) \
                           .time_table_period(period) \
                           .between_stop_areas(from_stop_area, to_stop_area) \
                           .where_departure_time_between(
                             departure_time_start,
                             departure_time_end,
                             allow_empty: departure_time_allow_empty
                           )
    end

    private

    def journey_pattern
      Chouette::JourneyPattern.new(id: journey_pattern_id) if journey_pattern_id.present?
    end

    class Order < ::Search::Order
      attribute :published_journey_name, default: :asc
      attribute :departure_time, column: :departure_second_offset
      attribute :arrival_time, column: :arrival_second_offset
    end
  end
end
