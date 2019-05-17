module Chouette
  class LineNotice < Chouette::ActiveRecord
    has_metadata
    include LineReferentialSupport
    include ObjectidSupport

    scope :for_vehicle_journey, -> (vehicle_journey){
      joins('INNER JOIN public.line_notices_vehicle_journeys ON line_notices_vehicle_journeys.line_notice_id = line_notices.id').where("line_notices_vehicle_journeys.vehicle_journey_id = ?", vehicle_journey.id)
    }

    # We will protect the notices that are used by vehicle_journeys
    scope :unprotected, -> {
      subquery = CrossReferentialIndexEntry.where(relation_name: :line_notices).select(:parent_id).distinct
      where.not("id in (#{subquery.to_sql})" )
    }

    belongs_to :line_referential, inverse_of: :line_notices
    has_and_belongs_to_many :lines, :class_name => 'Chouette::Line', :join_table => "line_notices_lines"
    has_many_scattered :vehicle_journeys

    validates_presence_of :title

    alias_attribute :name, :title

    def self.nullable_attributes
      [:content, :import_xml]
    end

    def protected?
      vehicle_journeys.exists?
    end
  end
end
