module Control

  class CodeFormat < Control::Base
    enumerize :target_model, in: %w{Line StopArea VehicleJourney}, default: "Line"
    option :target_model
    option :target_code_space_id
    option :expected_format

    validates :target_model, :target_code_space_id, :expected_format, presence: true

    class Run < Control::Base::Run
      option :target_model
      option :target_code_space_id
      option :expected_format

      def run
        faulty_models.includes(:codes).find_each do |model|
          control_messages.create({
            message_attributes: { code_values: code_values(model) },
            criticity: criticity,
            source: model,
          })
        end
      end

      def code_values(model)
        model.codes.pluck(:value).select do | code_value |
          code_value.match(Regexp.new(expected_format)).blank?
        end
      end

      def model_class
        @model_class ||=
          "Chouette::#{target_model}".constantize rescue nil || target_model.constantize
      end

      def code_model
        unless model_class == Chouette::VehicleJourney
          :codes
        else
          :referential_codes
        end
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