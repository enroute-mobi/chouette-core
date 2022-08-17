class Entrance < ActiveRecord::Base
  include StopAreaReferentialSupport
  include ObjectidSupport
  include CodeSupport
  extend Enumerize

  belongs_to :stop_area, class_name: 'Chouette::StopArea', optional: false
  has_one :raw_import, as: :model, dependent: :delete
  accepts_nested_attributes_for :raw_import

  has_many :codes, as: :resource, dependent: :delete_all

  enumerize :entrance_type, in: %i(opening open_door door swing_door revolving_door automatic_door ticket_barrier gate other), scope: true

  validates :name, presence: true
  attr_writer :position_input

  scope :without_address, -> { where("country_code IS NULL OR street_name IS NULL OR zip_code IS NULL OR address IS NULL") }

  def position_input
    @position_input || ("#{position.y} #{position.x}" if position)
  end

  def longitude
    position&.x
  end
  def latitude
    position&.y
  end

  def entry?
    entry_flag
  end

  def exit?
    exit_flag
  end

  before_validation :position_from_input
  def position_from_input
    PositionInput.new(@position_input).change_position(self)
  end

  def address_=(address)
    self.country = address.country_name
    self.address = [ address.house_number, address.street_name ].join(' ')
    self.zip_code = address.post_code
    self.city_name = address.city_name
  end
end
