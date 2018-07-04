module Chouette
  class TextAndNumericalType < ActiveSupport::StringInquirer
    DEFINITIONS = []

    def initialize(text_code, numerical_code)
      super text_code.to_s
      @numerical_code = numerical_code
    end

    def self.new(text_code, numerical_code = nil)
      return super if text_code && numerical_code
      return text_code if text_code.is_a?(self)

      text_code, numerical_code = if text_code.is_a?(Integer)
                                    definitions.rassoc(text_code)
                                  else
                                    definitions.assoc(text_code.to_s)
                                  end

      super text_code, numerical_code
    end

    def to_i
      @numerical_code
    end

    def inspect
      "#{self}/#{to_i}"
    end

    def name
      camelize
    end

    def self.definitions
      self::DEFINITIONS
    end

    @@all = nil
    def self.all
      @@all ||= definitions.map do |text_code, numerical_code|
        new(text_code, numerical_code)
      end
    end
  end
end
