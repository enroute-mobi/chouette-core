# TODO Make a standalone Geo module
require 'geo_ext.rb'

# Transform the position input into position when defined and valid
class PositionInput
  def initialize(input)
    @input = input
  end

  def change_position(model)
    if blank?
      model.position = nil
    elsif valid?
      model.position = position
    else
      model.errors.add :position_input
    end
  end

  def position
    geo_position.to_point
  end

  attr_reader :input
  delegate :blank?, to: :input

  def geo_position
    Geo::Position.parse(input)
  end
  delegate :valid?, to: :geo_position, allow_nil: true
end
