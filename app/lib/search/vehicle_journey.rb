# frozen_string_literal: true

module Search
  class VehicleJourney < Base
    attr_accessor :referential

    attribute :text
    attribute :company_id
    attribute :line_id
    attribute :time_table_id
    attribute :start_date, type: Date
    attribute :end_date, type: Date
    attribute :from_stop_area_id
    attribute :to_stop_area_id

    def period
      Period.new(from: start_date, to: end_date).presence
    end

    validates :start_date, presence: true, if: proc { |search| search.end_date.present? }
    validates :end_date, presence: true, if: proc { |search| search.start_date.present? }
    validates :period, valid: true
    validates :company, inclusion: { in: ->(search) { search.candidate_companies } }, allow_blank: true, allow_nil: true
    validates :line, inclusion: { in: ->(search) { search.candidate_lines } }, allow_blank: true, allow_nil: true
    validates :time_table, inclusion: { in: ->(search) { search.candidate_time_tables } }, allow_blank: true, allow_nil: true
    validates :from_stop_area, inclusion: { in: lambda { |search|
                                                  search.candidate_stop_areas
                                                } }, allow_blank: true, allow_nil: true
    validates :to_stop_area, inclusion: { in: lambda { |search|
                                                search.candidate_stop_areas
                                              } }, allow_blank: true, allow_nil: true

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

    def query(scope)
      Query::VehicleJourney.new(scope).text(text).company(company).line(line).time_table(time_table).time_table_period(period).between_stop_areas(
        from_stop_area, to_stop_area
      )
    end

    class Order < ::Search::Order
      attribute :published_journey_name, default: :asc
      attribute :departure_time, column: :departure_second_offset
      attribute :arrival_time, column: :arrival_second_offset
    end
  end
end
