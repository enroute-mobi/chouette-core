# frozen_string_literal: true

module Chouette
  class Footnote < Referential::ActiveRecord
    include ChecksumSupport
    include ReferentialCodeSupport

    belongs_to :line, inverse_of: :footnotes, optional: true
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

    alias_attribute :name, :code

    def checksum_attributes(_db_lookup = true)
      attrs = %w[code label line_id]
      slice(*attrs).values
    end
  end
end
