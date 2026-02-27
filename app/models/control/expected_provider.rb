module Control

  class ExpectedProvider < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        enumerize :target_model, in: %w[
          StopArea ConnectionLink Entrance
          RoutingConstraint Company
          Line LineNotice Network
          Document PointOfInterest Shape
        ]
        option :expected_provider
        enumerize :expected_provider, in: %w[all_workbench_provider workbench], default: 'all_workbench_provider'

        validates :target_model, :expected_provider, presence: true
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          messages.create(source: model)
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
        ].find { |provider| model_class.reflections[provider] }
      end

      def provider_collection
        provider_attribute.pluralize
      end

      def expected_providers
        workbench.send provider_collection
      end

      def faulty_models
        if expected_provider == 'all_workbench_provider'
          models.where.not(provider_attribute => expected_providers)
        elsif expected_provider == 'workbench'
          models.where.not(id: workbench.send(model_collection))
        end
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize.to_sym
      end

      def models
        @models ||= context.send(model_collection)
      end
    end
  end
end
