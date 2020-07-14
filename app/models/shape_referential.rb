class ShapeReferential < ApplicationModel

  has_one :workgroup
  has_many :shape_providers
  has_many :shapes

end
