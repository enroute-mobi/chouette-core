# Transform the position input into position when defined and valid
class PositionInput
  def initialize(input, attribute: :position)
    @input = input
    @attribute = attribute
  end

  def change(model)
    if blank?
      model.send "#{attribute}=", nil
    elsif valid?
      model.send "#{attribute}=", position
    else
      model.errors.add "#{attribute}_input"
    end
  end

  def position
    geo_position.to_point
  end

  attr_reader :input, :attribute

  delegate :blank?, to: :input

  def geo_position
    Geo::Position.parse(input)
  end
  delegate :valid?, to: :geo_position, allow_nil: true
end
