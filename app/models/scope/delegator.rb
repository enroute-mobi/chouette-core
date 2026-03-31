# frozen_string_literal: true

module Scope
  class Delegator < Base
    def initialize(object)
      super()
      @object = object
    end
    attr_reader :object

    def scopes?(name)
      supported?(name) || super
    end

    def collection(name, **)
      if supported?(name)
        object.send(name)
      else
        super
      end
    end

    private

    def supported?(name)
      self.class::SUPPORTED.include?(name)
    end
  end
end
