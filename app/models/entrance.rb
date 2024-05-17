# frozen_string_literal: true

class Entrance < ActiveRecord::Base
  include NilIfBlank
  include StopAreaReferentialSupport
  include ObjectidSupport
  include CodeSupport
  extend Enumerize

  belongs_to :stop_area, class_name: 'Chouette::StopArea', optional: false
  has_one :raw_import, as: :model, dependent: :delete
  accepts_nested_attributes_for :raw_import

  has_many :codes, as: :resource, dependent: :delete_all

  enumerize :entrance_type,
            in: %i[opening open_door door swing_door revolving_door automatic_door ticket_barrier gate other], scope: true

  validates :name, presence: true
  attr_writer :position_input

  # rubocop:disable Naming/VariableNumber
  scope :without_address, -> { where country: nil, city_name: nil, zip_code: nil, address_line_1: nil }
  scope :with_position, -> { where.not position: nil }

  def self.nullable_attributes
    %i[
      address_line_1
      zip_code
      city_name
      country
      postal_region
    ]
  end
  # rubocop:enable Naming/VariableNumber

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
    PositionInput.new(@position_input).change(self)
  end

  def address=(address)
    self.country = address.country_name
    self.address_line_1 = address.house_number_and_street_name
    self.zip_code = address.post_code
    self.city_name = address.city_name
  end
end
