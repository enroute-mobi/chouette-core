# frozen_string_literal: true

module Macro
  class DefinePostalAddress < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :reverse_geocoder_provider

        enumerize :target_model, in: %w[StopArea Entrance PointOfInterest]
        enumerize :reverse_geocoder_provider, in: %i[default french_ban], default: :default

        validates :target_model, presence: true
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        models.find_in_batches(batch_size: 100) do |group|
          batch = reverse_geocode.batch

          group.each do |model|
            batch.address model.position, key: model.id
          end

          models_by_ids = group.map { |model| [model.id, model] }.to_h

          batch.addresses.each do |key, address|
            model = models_by_ids[key]
            Updater.new(model, address, macro_messages).update
          end
        end
      end

      def reverse_geocode
        case reverse_geocoder_provider
        when 'french_ban'
          ReverseGeocode::Config.new do |config|
            config.resolver_classes << ReverseGeocode::Resolver::FrenchBAN
            config.resolver_classes << ReverseGeocode::Resolver::Cache
          end
        else
          workgroup.reverse_geocode
        end
      end

      # Update a model with a given address with associated message
      class Updater
        def initialize(model, address, messages = nil)
          @model = model
          @address = address
          @messages = messages
        end

        def update
          unless address
            create_message criticity: 'warning', message_key: 'no_address'
            return
          end

          if model.update address: address
            create_message
          else
            create_message criticity: 'error', message_key: 'error'
          end
        end

        attr_reader :model, :messages, :address

        def create_message(attributes = {})
          return unless messages

          attributes.merge!(
            message_attributes: { name: model.name, address: address.to_s },
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
    end
  end
end
