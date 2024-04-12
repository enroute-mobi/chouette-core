# frozen_string_literal: true

module ReferentialCodeSupport
  extend ActiveSupport::Concern

  included do
    include CodeSupport

    has_many :codes, class_name: 'ReferentialCode', as: :resource, dependent: :delete_all

    scope :by_code, lambda { |code_space, value|
      joins(:codes).where('referential_codes.code_space_id': code_space.id, 'referential_codes.value': value)
    }

    scope :without_code, lambda { |code_space|
      where.not(id: joins(:codes).where('referential_codes.code_space_id': code_space.id))
    }

    def self.code_table
      ReferentialCode.arel_table
    end
  end
end
