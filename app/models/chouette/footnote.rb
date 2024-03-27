# frozen_string_literal: true

module Chouette
  class Footnote < Referential::ActiveRecord
    include ChecksumSupport

    belongs_to :line, inverse_of: :footnotes
    has_and_belongs_to_many :vehicle_journeys, class_name: 'Chouette::VehicleJourney'

    scope :associated, lambda {
      joins(:vehicle_journeys).where('vehicle_journeys.id is not null')
    }

    scope :not_associated, lambda {
      joins('LEFT JOIN "footnotes_vehicle_journeys" ON footnotes_vehicle_journeys.footnote_id = footnotes.id')
        .where('footnotes_vehicle_journeys.vehicle_journey_id is null')
    }

    scope :for_vehicle_journey, lambda { |vehicle_journey|
      joins('INNER JOIN "footnotes_vehicle_journeys" ON footnotes_vehicle_journeys.footnote_id = footnotes.id').where('footnotes_vehicle_journeys.vehicle_journey_id = ?', vehicle_journey.id)
    }

    validates :line, presence: true

    def checksum_attributes(_db_lookup = true)
      attrs = %w[code label]
      slice(*attrs).values
    end
  end
end
