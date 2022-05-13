module Control

  class CodeFormat < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        enumerize :target_model, in: %w{Line StopArea VehicleJourney}
        option :target_model
        option :target_code_space_id
        option :expected_format

        validates :target_model, :target_code_space_id, :expected_format, presence: true

        def target_code_space
          @target_code_space ||= workgroup.code_spaces.find_by_id(target_code_space_id)
        end
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
              code_space_name: target_code_space.short_name,
              expected_format: expected_format
            },
            criticity: criticity,
            source: model,
            message_key: :code_format
          })
        end
      end

      def model_class
        @model_class ||=
          "Chouette::#{target_model}".constantize rescue nil || target_model.constantize
      end

      def code_model
        model_class.reflections["codes"].class_name.underscore.pluralize.to_sym
      end

      def faulty_models
        models.distinct.joins(codes: :code_space)
          .where.not("#{code_model}.value ~ ?", expected_format)
          .where(code_spaces: { id: target_code_space_id })
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