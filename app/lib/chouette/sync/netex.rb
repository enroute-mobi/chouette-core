module Chouette::Sync
  module Netex
    class Decorator < Chouette::Sync::Updater::ResourceDecorator
      def codes
        key_list.select(&type_of_key_filter('ALTERNATE_IDENTIFIER'))
      end

      def codes_attributes
        codes.map do |key_value|
          { short_name: key_value.key, value: key_value.value}
        end
      end

      def custom_fields
        key_list.select(&type_of_key_filter('chouette::custom-field'))
      end

      def custom_fields_attributes
        custom_fields.map do |key_value|
          { code: key_value.key, value: key_value.value}
        end
      end

      def particular?
        derived_from_object_ref.present?
      end

      protected

      def accessibility
        @accessibility ||= AccessibilityAssessment.new accessibility_assessment
      end

      class AccessibilityAssessment
        def initialize(accessibility_assessment)
          @accessibility_assessment = accessibility_assessment
        end
        attr_accessor :accessibility_assessment

        def limitation
          @limitation ||= accessibility_assessment&.limitations&.first
        end

        def transform(value)
          case value
          when 'true'
            'yes'
          when 'false'
            'no'
          when nil
            'unknown'
          else
            value
          end
        end

        def mobility_impaired_access
          transform accessibility_assessment&.mobility_impaired_access
        end

        def description
          accessibility_assessment&.description
        end

        def wheelchair_access
          transform limitation&.wheelchair_access
        end

        def step_free_access
          transform limitation&.step_free_access
        end

        def escalator_free_access
          transform limitation&.escalator_free_access
        end

        def lift_free_access
          transform limitation&.lift_free_access
        end

        def audible_signals_available
          transform limitation&.audible_signals_available
        end

        def visual_signs_available
          transform limitation&.visual_signs_available
        end
      end

      private

      def type_of_key_filter(value)
        Proc.new { |key_value| key_value.type_of_key == value }
      end
    end
  end
end
