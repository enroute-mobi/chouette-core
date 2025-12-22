# frozen_string_literal: true

# TODO: Should be a Operation::Part subclass in the future
module Import
  class Part
    def initialize(import)
      @import = import
    end

    attr_reader :import

    delegate :code_space, to: :import

    delegate :logger, to: :Rails

    # To define callback in import!
    include AroundMethod
    around_method :import!

    extend ActiveModel::Callbacks
    define_model_callbacks :import

    def around_import!(&block)
      run_callbacks :import do
        ::Bullet.profile do
          logger.tagged(internal_description, &block)
        end
      end
    end

    def internal_description
      @internal_description ||= self.class.name.demodulize.underscore
    end

    include Measurable
    measure :import!, as: ->(part) { part.internal_description }
  end
end
