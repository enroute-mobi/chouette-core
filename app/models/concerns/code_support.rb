module CodeSupport
  extend ActiveSupport::Concern

  included do
    has_many :codes, as: :resource, dependent: :delete_all
    accepts_nested_attributes_for :codes, allow_destroy: true, reject_if: :all_blank
    validates_associated :codes

    scope :by_code, ->(code_space, value) { joins(:codes).where(codes: { code_space: code_space, value: value }) }
    scope :without_code, ->(code_space) { where.not(id: joins(:codes).where(codes: { code_space_id: code_space })) }
  end
end