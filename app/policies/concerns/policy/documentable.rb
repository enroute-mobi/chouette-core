# frozen_string_literal: true

module Policy
  module Documentable
    extend ActiveSupport::Concern

    protected

    def _create?(resource_class)
      if resource_class == ::DocumentMembership
        apply_strategies(:update)
      else
        super
      end
    end
  end
end
