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
          group.each { |model| Updater.new(model, macro_messages).update }

          sleep 1
        end
      end

      class Updater
        def initialize(model, messages = nil)
          @model = model
          @messages = messages
        end
        attr_reader :model, :messages

        def update
          unless postal_region
            create_message criticity: 'warning', message_key: 'no_insee_code'
            return
          end

          if model.update postal_region: postal_region
            create_message
          else
            create_message criticity: 'error', message_key: 'error'
          end
        end

        def postal_region
          @postal_region ||= Insee.new(lat: model.latitude, lon: model.longitude).code
        end

        def create_message(attributes = {})
          return unless messages

          attributes.merge!(
            message_attributes: { name: model.name, postal_region: postal_region },
            source: model
          )
          messages.create!(attributes)
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
          @body ||= response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body).first : {}
        end

        def code
          @code ||= body['code']
        end
      end

      def models_without_postal_region
        @models_without_postal_region ||= models.where(postal_region: nil)
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
