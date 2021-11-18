class Entrance < ActiveRecord::Base
  include StopAreaReferentialSupport
  include ObjectidSupport
  extend Enumerize

  belongs_to :stop_area, class_name: 'Chouette::StopArea', optional: false
  has_one :raw_import, as: :model, dependent: :delete

  enumerize :entrance_type, in: %i(opening open_door door swing_door revolving_door automatic_door ticket_barrier gate other), scope: true

  validates :name, presence: true
  attr_writer :position_input

  def position_input
    @position_input || ("#{position.x} #{position.y}" if position)
  end

  before_validation :position_from_input

  def position_from_input
    self.position = "POINT(#{position_input})" if @position_input
  end
end
