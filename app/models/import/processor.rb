# frozen_string_literal: true

module Import
  class Processor < ::Processor
    protected

    def before_referentials
      nil
    end

    def after_referentials
      [operation.referential].compact
    end
  end
end
