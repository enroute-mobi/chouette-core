# frozen_string_literal: true
module Search
  class VehicleJourney < Base

    attribute :text
    attribute :company
    attribute :line
    attribute :start_date, type: Date
    attribute :end_date, type: Date
    attribute :from_stop_area, :to_stop_area

    def period
      Period.new(from: start_date, to: end_date).presence
    end

    validates :period, valid: true
    validates :company, inclusion: { in: ->(search) { search.candidate_companies } }
    validates :line, inclusion: { in: ->(search) { search.candidate_lines } }
    validates :from_stop_area, inclusion: { in: ->(search) { search.candidate_stop_areas } }
    validates :to_stop_area, inclusion: { in: ->(search) { search.candidate_stop_areas } }

    def candidate_lines
      scope.lines
    end

    def candidate_companies
      scope.companies
    end

    def candidate_stop_areas
      scope.companies
    end

    def query
      Query::VehicleJourney.new(scope).text(text).company(company).line(line).time_table(period).between_stop_areas(from_stop_area, to_stop_area)
    end

    class Order < ::Search::Order
      attribute :published_journey_name, default: :asc
    end
  end
end
