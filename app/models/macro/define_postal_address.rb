module Macro
  class DefinePostalAddress < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        enumerize :target_model, in: %w[StopArea Entrance PointOfInterest]
        validates :target_model, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        models.find_each do |model|
          # Find by position to use the same Address in the same area
          address = reverse_geocode.address(model.position)
          unless address
            create_message model, criticity: 'warning', message_key: 'no_address'
            next
          end

          if model.update address: address
            create_message model, criticity: 'info'
          else
            create_message model, criticity: 'warning', message_key: 'invalid_address'
          end
        end
      end

      def create_message(model, attributes)
        attributes.merge!(
          message_attributes: { name: model.name },
          source: model
        )
        macro_messages.create!(attributes)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= scope.send(model_collection).with_position.without_address
      end

      delegate :reverse_geocode, to: :workgroup
    end
  end
end
