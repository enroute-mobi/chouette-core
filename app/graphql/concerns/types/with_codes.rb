# frozen_string_literal: true

module Types
  module WithCodes
    extend ActiveSupport::Concern

    included do
      field :codes, GraphQL::Types::JSON, null: true
    end

    def codes
      object.codes.group_by { |c| c.code_space.short_name }.transform_values do |codes|
        code_values = codes.map(&:value).sort

        if code_values.many?
          code_values
        else
          code_values.first
        end
      end
    end
  end
end
