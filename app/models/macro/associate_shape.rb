module Macro
  class AssociateShape < Macro::Base
    class Run < Macro::Base::Run
      def run
        return unless referential
        return unless code_space

        journey_patterns.where(shape: nil).find_each do |journey_pattern|
          shape = shapes.by_code(code_space, journey_pattern.name).first
          journey_pattern.update shape: shape
        end
      end

      def journey_patterns
        referential.journey_patterns
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
