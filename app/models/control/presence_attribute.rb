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
          if attribute_or_method_klass? || belongs_to_itself?
            value = object.send(model_attribute_name) rescue nil
            next if value.present?
          end

          self.control_messages.create({
            message_attributes: { attribute_name: target_attribute },
            criticity: self.criticity,
            message_key: :no_presence_of_attribute,
            source: object,
          })
        end
      end

      def faulty_models
        if belongs_to_itself?
          # TODO: the referent and parent attributes don't work with left_joins
          models
        elsif belongs_to_attribute?
          models.left_joins(model_attribute_name).where(association_collection => { id: nil })
        elsif attribute_or_method_klass?
          condition = model_attribute.options[:source_sql_attributes].map{ |a| "#{a} IS NULL" }.join(" OR ")
          models.where(condition)
        else
          models.where(model_attribute_name => nil)
        end
      end

      def belongs_to_itself?
        model_attribute.options[:belongs_to_itself] || false
      end

      def belongs_to_attribute?
        model_attribute.options[:is_ref]
      end

      def attribute_or_method_klass?
        model_attribute.options[:source_sql_attributes].present?
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
    end
  end
end
