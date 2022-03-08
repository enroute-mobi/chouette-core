module Control
  class PresenceAttribute < Control::Base
    enumerize :target_model, in: %w{Line StopArea JourneyPattern VehicleJourney Company}, default: "Line"
    option :target_model
    option :target_attribute

    validates :target_model, :target_attribute, presence: true

    class Run < Control::Base::Run
      option :target_model
      option :target_attribute

      def run
        faulty_models.find_each do |object|
          if source_attributes.present? || self_reference?
            value = object.send(model_attribute_name) rescue nil
            next if value.present?
          end

          control_messages.create({
            message_attributes: { attribute_name: target_attribute },
            criticity: criticity,
            source: object,
          })
        end
      end

      def faulty_models
        if self_reference?
          models
        elsif reference?
          models.left_joins(model_attribute_name).where(association_collection => { id: nil })
        elsif source_attributes
          condition = source_attributes.map{ |a| "#{a} IS NULL" }.join(" OR ")
          models.where(condition)
        else
          models.where(model_attribute_name => nil)
        end
      end

      def source_attributes
        @source_attributes ||= model_attribute.options[:source_attributes]
      end

      def self_reference?
        @self_referent ||= belongs_to_attributes.find do |e|
          e.name == model_attribute_name &&
          e.options.dig(:class_name) == model_class.name
        end.present?
      end

      def reference?
        @referent ||= model_attribute.options[:reference] || false
      end

      def belongs_to_attributes
        @belongs_to_attributes ||=
          models.reflect_on_all_associations.select { |a| a.macro == :belongs_to }
      end

      def association_collection
        @association_collection ||= model_attribute.name.to_s.pluralize.to_sym
      end

      def model_attribute_name
        @model_attribute_name ||= model_attribute.name
      end

      def model_attribute
        @model_attribute ||= ::ModelAttribute.find_by_code(model_attribute_code)
      end

      def model_attribute_code
        @model_attribute_code ||= "#{target_model.underscore}##{target_attribute}"
      end

      def model_collection
        @model_collection ||= target_model.underscore.pluralize.to_sym
      end

      def models
        @models ||= context.send(model_collection)
      end

      def model_class
        @model_class ||=
          "Chouette::#{target_model}".constantize rescue nil || target_model.constantize
      end
    end
  end
end