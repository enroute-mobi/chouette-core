# frozen_string_literal: true

module Scope
  class Composer
    def initialize(default_stack, **stacks)
      @default_stack = default_stack
      @stacks = stacks
      @collections = {}
    end
    attr_reader :default_stack, :stacks

    def collection(name)
      return @collections[name] if @collections.key?(name)

      @collections[name] ||= create_collection(name)
    end

    private

    def respond_to_missing?(method, _include_all)
      collection(method.to_sym) || super
    end

    def method_missing(method, *args, **options, &_block)
      if args.empty? && options.empty? && !block_given?
        collection = collection(method.to_sym)
        return collection if collection
      end

      super
    end

    def stack(name)
      stacks.fetch(name, default_stack)
    end

    def create_collection(name)
      current_collection = nil

      stack(name).each do |scope|
        scope.global_scope ||= self

        next unless scope.scopes?(name)

        # TODO: find a way to not call #collection on a scope if the next one will never use it:
        #   collection do |current_scope| and then retrieve block arity

        current_collection = scope.collection(name, current_collection: current_collection)
      end

      current_collection
    end
  end
end
