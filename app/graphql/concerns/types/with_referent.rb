# frozen_string_literal: true

module Types
  module WithReferent
    extend ActiveSupport::Concern

    included do
      field :is_referent, GraphQL::Schema::Object::Boolean, null: true
      field :referent, self, null: true
    end

    def referent
      referential_lazy_loading_relation_class.new(context, object.referent_id) if object.referent_id
    end

    protected

    def referential_lazy_loading_relation_class
      raise NotImplementedError
    end
  end
end
