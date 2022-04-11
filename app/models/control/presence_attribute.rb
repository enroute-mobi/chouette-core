module Control
  class PresenceAttribute < Control::Base

    module Options
      extend ActiveSupport::Concern

      included do
        option :target_model
        option :target_attribute

        enumerize :target_model, in: %w{Line StopArea JourneyPattern VehicleJourney Company}, default: "Line"
        validates :target_model, :target_attribute, presence: true
      end
    end
    include Options

    class Run < Control::Base::Run
      include Options

      def run
        faulty_models.find_each do |model|
          control_messages.create!({
            message_attributes: { name: (model.name rescue model.id) },
            criticity: criticity,
            source: model,
          })
        end
      end

      def faulty_models
        finder.faulty_models
      end

      def finder
        Finder.create models, model_attribute
      end

      class Finder
        attr_accessor :scope, :model_attribute

        def initialize(scope, model_attribute)
          @scope = scope
          @model_attribute = model_attribute
        end

        def self.create(scope, model_attribute)
          with_query = WithQuery.create(scope, model_attribute)
          return with_query if with_query

          if model_attribute.options[:reference]
            Reference.new scope, model_attribute
          else
            SimpleAttribute.new scope, model_attribute
          end
        end
      end

      class SimpleAttribute < Finder
        def faulty_models
          scope.where(model_attribute.name => nil)
        end
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