# frozen_string_literal: true

module Scope
  class Base
    class << self
      def inherited(base)
        base.instance_variable_set(:@collections, @collections.dup) if defined?(@collections)
        super
      end

      def collection(name, &block)
        collections[name] = block
      end
      alias attribute collection

      def collections
        @collections ||= {}
      end
    end

    attr_accessor :global_scope

    def scopes?(name)
      self.class.collections.key?(name)
    end

    def collection(name, current_collection:)
      Invoker.new(self, current_collection: current_collection).instance_eval(&self.class.collections[name])
    end

    class Invoker < SimpleDelegator
      def initialize(scope, current_collection:)
        super(scope)
        @current_collection = current_collection
      end
      attr_reader :current_collection
      alias current_value current_collection
    end
  end
end
