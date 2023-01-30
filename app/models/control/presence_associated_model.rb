module Control
    class PresenceAssociatedModel < Control::Base

      module Options
        extend ActiveSupport::Concern

        included do
          option :target_model
          option :collection
          option :minimum
          option :maximum

          enumerize :target_model, in: %w{Referential Line StopArea Company Route JourneyPattern VehicleJourney TimeTable}
          validates :target_model, :collection, presence: true
          validates :minimum, :maximum, numericality: { only_integer: true, allow_nil: true }
        end
      end
      include Options

      validate :minimum_or_maximum

      def candidate_collections
        Chouette::ModelAttribute.empty do
          define Referential, :lines
          define Referential, :routes
          define Referential, :vehicle_journeys
          define Referential, :time_tables

          define Chouette::StopArea, :routes
          define Chouette::StopArea, :lines
          define Chouette::StopArea, :Entrances
          define Chouette::StopArea, :connection_links

          define Chouette::Line, :routes
          define Chouette::Line, :secondary_companies

          define Chouette::Route, :stop_points
          define Chouette::Route, :journey_patterns
          define Chouette::Route, :vehicle_journeys

          define Chouette::JourneyPattern, :stop_points
          define Chouette::JourneyPattern, :vehicle_journeys

          define Chouette::VehicleJourney, :time_tables

          define Chouette::TimeTable, :periods
          define Chouette::TimeTable, :dates
        end
      end

      private

      def minimum_or_maximum
        return if minimum.present? || maximum.present?

        errors.add(:minimum, :invalid)
      end

      class Run < Control::Base::Run
        include Options

        def run
          faulty_models.each do |model|
            control_messages.create(message_attributes: { name: model.try(:name) || model.id },
                                    criticity: criticity,
                                    source: model,
                                    message_key: :presence_associated_model)
          end
        end

        def context_collection
          case [target_model, collection]
          when %w[JourneyPattern stop_points]
            'journey_pattern_stop_points'
          else
            collection
          end
        end

        def faulty_models
          context
            .send(context_collection)
            .group(target_model.underscore)
            .having(condition, { minimum: minimum, maximum: maximum })
            .count
            .keys
        end

        def condition
          if minimum.present? && maximum.present?
            'count(*) < :minimum or count(*) > :maximum'
          elsif minimum.present?
            'count(*) < :minimum'
          else
            'count(*) > :maximum'
          end
        end
      end
    end
  end
  