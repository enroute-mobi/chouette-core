module Macro
  class AssociateShape < Macro::Base
    class Run < Macro::Base::Run
      def run
        return unless code_space

        journey_patterns.find_each do |journey_pattern|
          shape = shapes.by_code(code_space, journey_pattern.name).first
          #  If no shape found Chouette goes to the next journey_pattern
          if shape.present?
            journey_pattern.update(shape: shape)
            create_message(journey_pattern, shape)
          end
        end
      end

      # Create a message for the given JourneyPattern
      # If the JourneyPattern is invalid, an error message is created.
      def create_message(journey_pattern, shape)
        attributes = {
          criticity: 'info',
          message_attributes: { shape_name: shape.uuid, journey_pattern_name: journey_pattern.name },
          source: journey_pattern
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless journey_pattern.valid?

        macro_messages.create!(attributes)
      end

      def journey_patterns
        scope.journey_patterns.where(shape: nil)
      end

      def shapes
        workgroup.shape_referential.shapes
      end

      def code_space
        @code_space ||= workgroup.code_spaces.find_by(short_name: 'external')
      end
    end
  end
end
