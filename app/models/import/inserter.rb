# frozen_string_literal: true

module Import
  # Insert a model into a Referential (via ReferentialInserter).
  class Inserter
    def initialize(referential_inserter, on_invalid: nil, on_save: nil)
      @referential_inserter = referential_inserter
      @invalid_handler = on_invalid
      @save_handler = on_save
    end

    attr_reader :referential_inserter

    def valid?(model)
      if model.valid?(:inserter)
        true
      else
        Rails.logger.debug { "Invalid model: #{model.inspect} #{model.errors.inspect}" }
        @invalid_handler&.call model
        false
      end
    end

    def saved(model)
      @save_handler&.call model
    end

    delegate :flush, to: :referential_inserter

    include AroundMethod

    around_method :insert
    def around_insert(model, &block)
      return unless valid?(model)

      block.call
      insert_codes model

      saved model
    end

    protected

    attr_reader :invalid_handler, :save_handler

    def insert_codes(resource)
      resource.codes.each do |code|
        code.resource = resource
        referential_inserter.codes << code
      end
    end
  end
end
