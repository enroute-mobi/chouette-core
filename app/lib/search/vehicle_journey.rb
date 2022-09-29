# frozen_string_literal: true

module Search
  class VehicleJourney < Base
    attr_accessor :referential

    attribute :text
    attribute :company_id
    attribute :line_id
    attribute :start_date, type: Date
    attribute :end_date, type: Date
    attribute :from_stop_area_id
    attribute :to_stop_area_id

    def period
      Period.new(from: start_date, to: end_date).presence
    end

    validates :period, valid: true
    validates :company, inclusion: { in: ->(search) { search.candidate_companies } }, allow_blank: true, allow_nil: true
    validates :line, inclusion: { in: ->(search) { search.candidate_lines } }, allow_blank: true, allow_nil: true
    validates :from_stop_area, inclusion: { in: ->(search) { search.candidate_stop_areas } }, allow_blank: true, allow_nil: true
    validates :to_stop_area, inclusion: { in: ->(search) { search.candidate_stop_areas } }, allow_blank: true, allow_nil: true

    def company
      referential.companies.find(company_id) if company_id.present?
    end

    def line
      referential.lines.find(line_id) if line_id.present?
    end

    def from_stop_area
      referential.stop_areas.find(from_stop_area_id) if from_stop_area_id.present?
    end

    def to_stop_area
      referential.stop_areas.find(to_stop_area_id) if to_stop_area_id.present?
    end

    def candidate_lines
      referential.lines
    end

    def candidate_companies
      referential.companies
    end

    def candidate_stop_areas
      referential.stop_areas
    end

    def query
      Query::VehicleJourney.new(scope).text(text).company(company).line(line).time_table(period).between_stop_areas(from_stop_area, to_stop_area)
    end

    class Order < ::Search::Order
      attribute :published_journey_name, default: :asc
    end
  end
end
