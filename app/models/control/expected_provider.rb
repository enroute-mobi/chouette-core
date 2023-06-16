module Control

  class ExpectedProvider < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        enumerize :target_model, in: %w{
          StopArea ConnectionLink Entrance
          StopArea RoutingConstraint Company
          Line LineNotice Network
          Document PointOfInterest Shape
        }
        option :expected_provider
        enumerize :expected_provider, in: %w{ all_workbench_provider }

        validates :target_model, :expected_provider, presence: true
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          control_messages.create({
            message_attributes: {
              name: model.try(:name) || model.id,
              expected_provider: expected_provider
            },
            criticity: criticity,
            source: model,
            message_key: :expected_provider
          })
        end
      end

      def model_class
        @model_class ||=
          "Chouette::#{target_model}".constantize rescue nil || target_model.constantize
      end

      def provider_attribute
        %w[
          stop_area_provider
          line_provider
          shape_provider
          document_provider
        ].find { |provier| model_class.reflections[provier] }
      end

      def provider_collection
        provider_attribute.pluralize
      end

      def expected_providers
        workbench.send provider_collection
      end

      def faulty_models
        models.where.not(provider_attribute => expected_providers)
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize.to_sym
      end

      def models
        @models ||= workbench.send(model_collection)
      end
    end
  end
end