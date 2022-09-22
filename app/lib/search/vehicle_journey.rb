# frozen_string_literal: true

module Search
  class VehicleJourney < Base
    attr_accessor :referential

    attribute :text
    attribute :company
    attribute :line
    attribute :start_date, type: Date
    attribute :end_date, type: Date
    attribute :from_stop_area
    attribute :to_stop_area

    def period
      Period.new(from: start_date, to: end_date).presence
    end

    validates :period, valid: true
    validates :company, inclusion: { in: ->(search) { search.candidate_companies } }, allow_nil: true
    validates :line, inclusion: { in: ->(search) { search.candidate_lines } }, allow_nil: true
    validates :from_stop_area, inclusion: { in: ->(search) { search.candidate_stop_areas } }, allow_nil: true
    validates :to_stop_area, inclusion: { in: ->(search) { search.candidate_stop_areas } }, allow_nil: true

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
