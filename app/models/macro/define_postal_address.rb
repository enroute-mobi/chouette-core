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
            Updater.new(self, model, address).update
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
        def initialize(macro_run, model, address)
          @macro_run = macro_run
          @model = model
          @address = address
        end
        attr_reader :macro_run, :model, :address

        delegate :messages, to: :macro_run

        def update
          success = model.update address: address if address

          messages.create(source: model, address: address.to_s) do |message|
            if !address
              message.error!(criticity: 'warning', message_key: 'no_address')
            elsif !success
              message.error!
            end
          end
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
