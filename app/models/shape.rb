class Shape < ApplicationModel

  belongs_to :shape_referential, required: true
  belongs_to :shape_provider, required: true

  has_many :codes, as: :resource, dependent: :delete_all

  validates :geometry, presence: true
  # TODO May be usefull, but must not impact performance
  # validates :shape_provider, inclusion: { in: ->(shape) { shape.shape_referential.shape_providers } }, if: :shape_referential

  before_validation :define_shape_referential, on: :create

  scope :by_code, ->(code_space, value) {
    joins(:codes).where(codes: { code_space: code_space, value: value })
  }

  private

  def define_shape_referential
    # TODO Improve performance ?
    self.shape_referential ||= shape_provider&.shape_referential
  end

end
