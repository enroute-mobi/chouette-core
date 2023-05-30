module Control
  class GeographicalZone < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        enumerize :target_model, in: %w[StopArea Entrance PointOfInterest]

        option :upper_left_input
        option :lower_right_input
        validates :target_model, :upper_left_input, :lower_right_input, presence: true

        attr_writer :upper_left, :lower_right

        before_validation :positions_from_inputs
      end

      def upper_left
        @upper_left ||= Geo::Position.parse(upper_left_input)&.to_point
      end

      def lower_right
        @lower_right ||= Geo::Position.parse(lower_right_input)&.to_point
      end

      def positions_from_inputs
        PositionInput.new(upper_left_input, attribute: :upper_left).change(self)
        PositionInput.new(lower_right_input, attribute: :lower_right).change(self)
      end
    end

    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          control_messages.create(
            message_attributes: {
              name: model.try(:name).presence || model.try(:uuid) || model.id
            },
            criticity: criticity,
            source: model,
            message_key: :geographical_zone
          )
        end
      end

      def bounds
        "ST_SetSRID(ST_MakeBox2D(ST_GeomFromText('#{upper_left}'), ST_GeomFromText('#{lower_right}')), 4326)"
      end

      def position
        target_model == 'StopArea' ? 'ST_SetSRID(ST_Point(longitude, latitude), 4326)' : "position::geometry"
      end

      def faulty_models
        models.where.not("ST_Within(#{position}, #{bounds})")
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end
