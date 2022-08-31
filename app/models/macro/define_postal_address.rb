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
        models.find_in_batches(batch_size: 100) do |group|
          batch = workgroup.reverse_geocode

          group.each do |model|
            batch.address model.position, key: model.id
          end

          models_by_ids = group.map { |model| [model.id, model] }.to_h

          batch.addresses.each do |key, address|
            model = models_by_ids[key]
            Updater.new(model, macro_messages).update(address)
          end
        end
      end

      # Update a model with a given address with associated message
      class Updater
        def initialize(model, messages = nil)
          @model = model
          @messages = messages
        end

        def update(address)
          unless address
            create_message criticity: 'warning', message_key: 'no_address'
            return
          end

          if model.update address: address
            create_message criticity: 'info'
          else
            create_message criticity: 'warning', message_key: 'invalid_address'
          end
        end

        attr_reader :model, :messages

        def create_message(attributes)
          return unless messages

          attributes.merge!(
            message_attributes: { name: model.name },
            source: model
          )
          messages.create!(attributes)
        end
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
