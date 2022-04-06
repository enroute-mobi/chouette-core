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

      class Reference < Finder
        def faulty_models
          scope.left_joins(model_attribute.name).where(association_collection => { id: nil })
        end

        def association_collection
          model_attribute.options[:association_collection] ||
          model_attribute.name.to_s.pluralize.to_sym
        end
      end

      class WithQuery < Finder
        def self.create(scope, model_attribute)
          with_query = new(scope, model_attribute)
          with_query if with_query.support?
        end

        def support?
          query.respond_to? query_method
        end

        def query_class
          Query.for model_attribute.klass rescue nil
        end

        def query
          @query ||= query_class.new scope if query_class
        end

        def query_method
          "without_#{model_attribute.name}"
        end

        def faulty_models
          query.send query_method
        end
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