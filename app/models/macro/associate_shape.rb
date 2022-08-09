module Macro
  class AssociateShape < Macro::Base
    class Run < Macro::Base::Run
      def run
        return unless code_space

        ::Macro::Message.transaction do
          journey_patterns.find_each do |journey_pattern|
            shape = shapes.by_code(code_space, journey_pattern.name).first
            if shape.present? && journey_pattern.update!(shape: shape)
              self.macro_messages.create(
                criticity: "info",
                message_attributes: { shape_name: shape.uuid, journey_pattern_name: journey_pattern.name},
                source: journey_pattern
              )
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
        @code_space ||= workgroup.code_spaces.find_by(short_name: "external")
      end
    end
  end
end
