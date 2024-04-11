# frozen_string_literal: true

class Code < AbstractCode
  # Helper class to manipulate (merge, reformat, etc.) Code value
  class Value
    def self.parse(definition)
      return nil if definition.blank?

      netex_objectid = Netex::ObjectId.parse(definition)
      return netex_objectid if netex_objectid

      new(definition)
    end

    attr_reader :definition
    alias to_s definition

    def inspect
      "<#Code::Value #{definition.inspect}>"
    end

    def ==(other)
      other && definition == other.to_s
    end

    def merge(other, type: nil)
      self.class.new("#{definition}-#{other}").change(type: type)
    end

    def self.merge(definition, other, type: nil)
      parse(definition).merge(other, type: type)
    end

    def initialize(definition)
      @definition = definition
      freeze
    end

    def change(type: nil)
      if type.present?
        self.class.new "#{type}:#{definition}"
      else
        self
      end
    end
  end
end
