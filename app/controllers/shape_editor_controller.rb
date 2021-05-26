class ShapeEditorController < ApplicationController
  def home
  end

  def get_waypoints
    render xml: File.read(Rails.root.join('tomtom.kml'))
  end
end
