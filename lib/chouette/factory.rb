module Chouette
  module Factory

    HIERARCHY = {
      organisation: [:user],

      workgroup: {
        line_referential: %i{line company network group_of_line},
        stop_area_referential: {
          stop_area: [:access_point],
          stop_area_provider: []
        },
        referential: {
          route: {
            stop_point: [],
            journey_pattern: {
              vehicle_journey: []
            },
            routing_constraint_zone: [],
            footnote: []
          },
          time_table: [],
          purchase_window: []
        }
      }
    }.freeze

    def self.create(&block)
      context = Context.new(Type.root)
      context.evaluate &block
      context.build
      context.save
    end

  end
end
