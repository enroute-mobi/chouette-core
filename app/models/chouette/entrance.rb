module Chouette
  class Entrance < Chouette::TridentActiveRecord
    belongs_to :stop_area, class_name: 'Chouette::StopArea'

    TYPE = %i(Opening Open Door Door Swing Door Revolving Door Automatic Door Ticket Barrier Gate).freeze
  end
end
