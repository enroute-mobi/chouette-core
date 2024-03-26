# frozen_string_literal: true

module Authentication
  class Base < ApplicationModel
    self.table_name = 'authentications'

    extend Enumerize
    include NilIfBlank

    belongs_to :organisation, inverse_of: :authentication, required: true

    validates :type, :name, presence: true
    validates :name, uniqueness: { scope: :organisation_id }

    def self.nullable_attributes
      %i[
        subtype
      ]
    end

    def subtype_data
      return nil unless subtype

      @subtype_data ||= self.class::Subtype.const_get(subtype.classify.to_sym)
    end
  end
end
