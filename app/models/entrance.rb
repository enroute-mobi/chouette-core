class Entrance < ActiveRecord::Base
  include StopAreaReferentialSupport
  include ObjectidSupport

  belongs_to :stop_area, class_name: 'Chouette::StopArea', optional: false

  TYPE = %w(Opening Open Door Door Swing Door Revolving Door Automatic Door Ticket Barrier Gate).freeze

  validates :name, presence: true
  validates :entrance_type, inclusion: { in: TYPE }, allow_blank: true

  attr_writer :position_input

  def position_input
    @position_input || ("#{position.x} #{position.y}" if position)
  end

  before_validation :position_from_input

  def position_from_input
    self.position = "POINT(#{position_input})" if @position_input
  end

end
