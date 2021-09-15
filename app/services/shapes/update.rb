module Shapes
  class Update < Shapes::Create

    def call
      super { shape.waypoints.destroy_all }
    end

    private

    def shape
      @shape ||= journey_pattern.shape
    end
  end
end