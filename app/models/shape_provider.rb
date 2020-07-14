class ShapeProvider < ApplicationModel

  belongs_to :shape_referential, required: true
  belongs_to :workbench, required: true
  has_many :shapes

  validates :short_name, presence: true

  before_validation :define_shape_referential, on: :create

  private

  def define_shape_referential
    self.shape_referential ||= workbench&.workgroup&.shape_referential
  end


end
