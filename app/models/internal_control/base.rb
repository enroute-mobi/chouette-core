module InternalControl
  class Base < ComplianceControl
    extend Rails.application.routes.url_helpers
    extend ActionDispatch::Routing::PolymorphicRoutes

    enumerize :criticity, in: %i(warning error), scope: true, default: :error

    def self.iev_enabled_check
      false
    end

    def self.optimize_routes_generation?
      false
    end

    def self.url_options
      {}
    end

    def self.enabled?(control_type)
      Rails.application.config.additional_compliance_controls.try :include?, control_type
    end

    def self.collection_type(_)
      :lines
    end

    def self.collection(compliance_check)
      if compliance_check.compliance_check_block
        compliance_check.compliance_check_block.collection(compliance_check)
      else
        compliance_check.referential.send(compliance_check.control_class.collection_type(compliance_check))
      end
    end

    def self.check compliance_check
      compliance_check.referential.switch do
        coll = collection(compliance_check)
        method = coll.respond_to?(:find_each) ? :find_each : :each

        control_instance = create_control_instance(compliance_check)

        coll.send(method) do |obj|
          begin
            compliant = control_instance.compliance_test(compliance_check, obj)
            status = status_ok_if(compliant, compliance_check)
            update_model_with_status compliance_check, obj, status
            unless compliant
              create_message_for_model compliance_check, obj, status, message_attributes(compliance_check, obj)
            end
          rescue
            update_model_with_status compliance_check, obj, "ERROR"
            raise
          end
        end
      end
    end

    class DefaultControl
      def initialize(klass, compliance_check)
        @klass = klass
      end

      def compliance_test(compliance_check, model)
        @klass.constantize.compliance_test compliance_check, model
      end
    end

    def self.create_control_instance(compliance_check)
      control_class = begin
                        "#{name}::Control".constantize
                      rescue NameError
                        DefaultControl
                      end

      control_class.new name, compliance_check
    end

    def self.resolve_compound_status status1, status2
      return [status1, status2].compact.last if status1.nil? || status2.nil?
      sorted_statuses = %w(IGNORED OK WARNING ERROR)
      sorted_statuses[[status1, status2].map{|k| sorted_statuses.index(k)}.max]
    end

    def self.status_ok_if compliant, compliance_check
      compliant ? "OK" : compliance_check.criticity.upcase
    end

    def self.message_key
      self.default_code.downcase.underscore
    end

    def self.resource_attributes compliance_check, model
      {
        label: model.send(label_attr(compliance_check)),
        objectid: model.objectid,
        attribute: label_attr(compliance_check),
        object_path: object_path(compliance_check, model)
      }
    end

    def self.custom_message_attributes compliance_check, object
      {source_objectid: object.objectid}
    end

    def self.message_attributes compliance_check, obj
      {
        test_id: compliance_check.origin_code,
        source_objectid: obj.objectid,
        source_object_path: object_path(compliance_check, obj)
      }.update(custom_message_attributes(compliance_check, obj))
    end

    def self.create_message_for_model compliance_check, model, status, message_attributes
      find_or_create_resources(compliance_check, model).each do |resource|
        compliance_check.compliance_check_set.compliance_check_messages.create do |message|
          message.compliance_check_resource = resource
          message.compliance_check = compliance_check
          message.message_attributes = message_attributes
          message.message_key = message_key
          message.status = status
          message.resource_attributes = resource_attributes(compliance_check, model)
        end
      end
    end

    def self.label_attr(compliance_check)
      :name
    end

    def self.lines_for compliance_check, model
      nil
    end

    def self.find_or_create_resources compliance_check, model
      lines = self.lines_for compliance_check, model
      lines ||= [model] if model.is_a?(Chouette::Line)
      lines ||= model.respond_to?(:lines) ? model.lines : [model.line]
      lines.map do |line|
        compliance_check.compliance_check_set.compliance_check_resources.find_or_create_by(
          reference: line.objectid,
          resource_type: line.class.model_name.singular,
          name: line.name
        )
      end
    end

    def self.update_model_with_status compliance_check, model, status
      find_or_create_resources(compliance_check, model).each do |resource|
        resource.metrics ||= {
          uncheck_count: 0,
          ok_count: 0,
          warning_count: 0,
          error_count: 0
        }

        new_status = resolve_compound_status resource.status, status
        metrics = resource.metrics.symbolize_keys
        metrics[metrics_key(status)] = [metrics[metrics_key(status)].to_i, 0].max + 1
        resource.update! status: new_status, metrics: metrics
      end
    end

    def self.metrics_key status
      {
        IGNORED: :uncheck_count,
        OK: :ok_count,
        WARNING: :warning_count,
        ERROR: :error_count
      }[status.to_sym]
    end
  end
end
