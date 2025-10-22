# frozen_string_literal: true

module Queries
  class BaseQuery < GraphQL::Schema::Resolver
    class << self
      attr_reader :scope_referential_method

      def scope(referential_method)
        @scope_referential_method = referential_method
      end
    end

    def resolve(**kwargs)
      scope(**kwargs)
    end

    protected

    def scope(**)
      context[:target_referential].send(self.class.scope_referential_method)
    end
  end
end
