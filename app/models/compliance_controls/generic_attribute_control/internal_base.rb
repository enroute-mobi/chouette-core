module GenericAttributeControl
  class InternalBase < InternalControl::Base
    store_accessor :control_attributes, :target

    validates :target, presence: true

    class << self
      def object_path(compliance_check, object)
        name = object.model_name.name
        klass = "#{name}Control::InternalBase".constantize

        klass.object_path(compliance_check, object)
      rescue NameError => e
        raise 'Could not find control class', e
      end

      def collection_type(compliance_check)
        resource_name(compliance_check)
          .pluralize
          .to_sym
      end

      private

      def resource_name compliance_check
        compliance_check
          .target
          .split('#')
          .first
      end

      def attribute_name compliance_check
        compliance_check
          .target
          .split('#')
          .last
      end
    end
  end
end