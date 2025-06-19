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
            messages.create(source: journey_pattern, shape_name: shape.uuid) do |message|
              message.error! unless journey_pattern.valid?
            end
          end
        end
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

      protected

      def messages_options
        {
          resource_name_key: :journey_pattern_name
        }
      end
    end
  end
end
