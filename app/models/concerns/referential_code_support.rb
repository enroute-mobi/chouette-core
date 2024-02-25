module ReferentialCodeSupport
  extend ActiveSupport::Concern

  included do
    include CodeSupport

    has_many :codes, class_name: 'ReferentialCode', as: :resource, dependent: :delete_all

    scope :by_code, ->(code_space, value) do 
      joins(:codes).where('referential_codes.code_space_id': code_space.id, 'referential_codes.value': value )
    end

    scope :without_code, ->(code_space) do 
      where.not(id: joins(:codes).where('referential_codes.code_space_id': code_space.id, ))
    end
  end
end