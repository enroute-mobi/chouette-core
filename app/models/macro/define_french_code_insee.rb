# frozen_string_literal: true

module Macro
  class DefineFrenchCodeInsee < Macro::Base
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

      BATCH_SIZE = 50

      def run
        models_without_postal_region.find_in_batches(batch_size: BATCH_SIZE) do |group|
          group.each { |model| Updater.new(self, model).update }

          sleep 1
        end
      end

      class Updater
        def initialize(macro_run, model)
          @macro_run = macro_run
          @model = model
        end
        attr_reader :macro_run, :model

        delegate :messages, to: :macro_run

        def update
          success = model.update postal_region: postal_region if postal_region

          messages.create(source: model, postal_region: postal_region) do |message|
            if !postal_region
              message.error!(criticity: 'warning', message_key: 'no_insee_code')
            elsif !success
              message.error!
            end
          end
        end

        def postal_region
          @postal_region ||= Insee.new(lat: model.latitude, lon: model.longitude).code
        end
      end

      class Insee
        def initialize(lat: nil, lon: nil)
          @lat = lat
          @lon = lon
        end
        attr_reader :lat, :lon

        def params
          @params ||= { lat: lat, lon: lon }
        end

        def uri
          @uri ||= URI('https://geo.api.gouv.fr/communes').tap do |uri|
            uri.query = URI.encode_www_form(params)
          end
        end

        def response
          @response ||= Net::HTTP.get_response(uri)
        end

        def body
          @body ||= response.is_a?(Net::HTTPSuccess) ? (JSON.parse(response.body).first || {}) : {}
        end

        def code
          @code ||= body['code']
        end
      end

      def models_without_postal_region
        @models_without_postal_region ||= models.where(postal_region: [nil, ''])
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize
      end

      def models
        @models ||= scope.send(model_collection).with_position
      end
    end
  end
end
