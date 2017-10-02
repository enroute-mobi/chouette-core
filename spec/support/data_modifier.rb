require_relative 'data_modifier/enum'
require_relative 'data_modifier/hash'
module Support
  module DataModifier
    module InstanceMethods
      CannotModify = Class.new RuntimeError

      def advance_values(atts, *keys)
        keys.inject(atts){ |h, k| h.merge( k => atts[k].next) }
      end

      # return array of atts wich each value modified, unboxing
      # values if needed
      def modify_atts(base_atts)
        base_atts.keys.map do | key |
          modify_att base_atts, key
        end.compact
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
        when Date
          value + 1.day
        when Box
          value.next.value
        else
          raise CannotModify
        end
      end
    end
  end
end

RSpec.configure do | c |
  c.include Support::DataModifier::InstanceMethods, type: :checksum
  c.include Support::DataModifier::InstanceMethods, type: :model
end
