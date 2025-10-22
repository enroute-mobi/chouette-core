# frozen_string_literal: true

module Queries
  module ByCode
    extend ActiveSupport::Concern

    included do
      argument :code, Types::CodeAttributes, required: false
    end

    protected

    def scope(code: nil, **kwargs)
      scope = super(**kwargs)

      if code
        code_space = context[:target_referential].workgroup.code_spaces.find_by(short_name: code.code_space)
        scope = if code_space
                  scope.by_code(code_space.id, code.value)
                else
                  scope.none
                end
      end

      scope
    end
  end
end
