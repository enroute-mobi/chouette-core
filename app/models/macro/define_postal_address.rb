module Macro
  class DefinePostalAddress < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        enumerize :target_model, in: %w{StopArea Entrance PointOfInterest}
        validates :target_model, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        models.each do |model|
          # Find by position to use the same Address in the same area
          address = Address.new(workgroup, model.position).address
          unless address
            macro_messages.create(
              criticity: "warning",
              message_key: "no_address",
              message_attributes: { name: model.name },
              source: model
            )

            next
          end

          if model.update address_: address
            macro_messages.create(
              criticity: "info",
              message_attributes: { name: model.name },
              source: model
            )
          else
            macro_messages.create(
              criticity: "warning",
              message_key: "invalid_address",
              message_attributes: { name: model.name },
              source: model
            )
          end
        end
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= scope.send(model_collection).without_address
      end

      class Address
        def initialize(workgroup, position)
          @position = position
          @workgroup = workgroup
        end
        attr_accessor :workgroup, :position

        def address
          workgroup.reverse_geocode.address(position)
        end
      end
    end
  end
end