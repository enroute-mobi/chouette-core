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

    def merge(other, **changes)
      self.class.new("#{definition}-#{other}").change(**changes)
    end

    def self.merge(definition, other, **changes)
      parse(definition).merge(other, **changes)
    end

    def initialize(definition)
      @definition = definition
      freeze
    end

    def change(country: nil, local: nil, type: nil, provider: nil)
      if country.present? || local.present? || type.present? || provider.present?
        self.class.new [country, local, type, definition, provider].compact.join(':')
      else
        self
      end
    end
  end
end
