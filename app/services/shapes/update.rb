module Shapes
  class Update < Shape::Create

    def call
      shape.waypoints.destroy_all
      super
    end

    private

    def shape
      @shape ||= journey_pattern.shape
    end
  end
end