class Entrance < ActiveRecord::Base
  belongs_to :stop_area, class_name: 'Chouette::StopArea'

  TYPE = %i(Opening Open Door Door Swing Door Revolving Door Automatic Door Ticket Barrier Gate).freeze
end
