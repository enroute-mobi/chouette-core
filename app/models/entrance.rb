class Entrance < ActiveRecord::Base
  belongs_to :stop_area, class_name: 'Chouette::StopArea', optional: false
  belongs_to :stop_area_provider, optional: false
  belongs_to :stop_area_referential, optional: false

  TYPE = %w(Opening Open Door Door Swing Door Revolving Door Automatic Door Ticket Barrier Gate).freeze

  validates :name, presence: true
  validates :entrance_type, inclusion: { in: TYPE }, allow_blank: true

end
