# frozen_string_literal: true

module Chouette
  module Sync
    module FareZone
      class Netex < Chouette::Sync::Base
        def initialize(options = {})
          default_options = {
            resource_type: :fare_zone,
            resource_id_attribute: :id,
            model_type: :fare_zone,
            resource_decorator: Decorator,
            model_id_attribute: :codes
          }
          options.reverse_merge!(default_options)
          super options
        end

        class Decorator < Chouette::Sync::Netex::Decorator
          def model_attributes
            {
              name: name,
              fare_geographic_references_attributes: fare_geographic_references_attributes
            }
          end

          def fare_geographic_references_attributes
            projections.map do |topographic_projection|
              { short_name: topographic_projection.ref }
            end
          end
        end
      end
    end
  end
end
