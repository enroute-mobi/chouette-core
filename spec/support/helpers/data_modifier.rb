require_relative 'data_modifier/enum'
module Support
  module Helpers
    module DataModifier
      CanotModify = Class.new RuntimeError
      # return array of atts wich each value modified
      def modify_atts(base_atts)
        base_atts.keys.map do | key |
          modify_att base_atts, key
        end.compact
      end

      def enum_value(*enum_values)
      end

      private
      def modify_att atts, key
        atts.merge(key => modify_value(atts[key]))
      rescue CannotModify
        nil
      end
      def modify_value value
        case value
        when String
          "#{value}."
        when Fixnum
          value + 1
        when TrueClass
          false
        when FalseClass
          true
        when Float
          value * 1.1
        when Value
          value.next.value
        else
          raise CannotModify
        end
      end
    end
  end
end

RSpec.configure do | c |
  c.include Support::Helpers::DataModifier, type: :checksum
end
