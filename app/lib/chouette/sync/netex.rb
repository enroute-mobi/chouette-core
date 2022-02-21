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

      private

      def type_of_key_filter(value)
        Proc.new { |key_value| key_value.type_of_key == value }
      end
    end
  end
end
