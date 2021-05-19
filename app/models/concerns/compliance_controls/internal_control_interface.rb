module ComplianceControls
  module InternalControlInterface
    extend ActiveSupport::Concern
    
    included do
      extend Rails.application.routes.url_helpers
      extend ActionDispatch::Routing::PolymorphicRoutes
    end

    class DefaultControl
      def initialize(klass, _compliance_check)
        @klass = klass
      end

      def compliance_test(compliance_check, model)
        @klass.compliance_test compliance_check, model
      end
    end

    class_methods do
      def iev_enabled_check
        false
      end

      def optimize_routes_generation?
        false
      end

      def url_options
        {}
      end

      def object_path(compliance_check, object)
        ComplianceControls::ObjectPathFinder.call(compliance_check, object)
      end

      def collection_type(_)
        :lines
      end

      def collection(compliance_check)
        if compliance_check.compliance_check_block
          compliance_check.compliance_check_block.collection(compliance_check)
        else
          compliance_check.referential.send(compliance_check.control_class.collection_type(compliance_check))
        end
      end

      def check compliance_check
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

      def create_control_instance(compliance_check)
        custom_class =
          begin
            "#{name}::Control".constantize
          rescue NameError
            nil
          end
        if custom_class
          custom_class.new compliance_check
        else
          DefaultControl.new self, compliance_check
        end
      end

      def resolve_compound_status status1, status2
        return [status1, status2].compact.last if status1.nil? || status2.nil?
        sorted_statuses = %w(IGNORED OK WARNING ERROR)
        sorted_statuses[[status1, status2].map{|k| sorted_statuses.index(k)}.max]
      end

      def status_ok_if compliant, compliance_check
        compliant ? "OK" : compliance_check.criticity.upcase
      end

      def message_key
        self.default_code.downcase.underscore
      end

      def resource_attributes compliance_check, model
        {
          label: model.send(label_attr(compliance_check)),
          objectid: model.objectid,
          attribute: label_attr(compliance_check),
          object_path: object_path(compliance_check, model)
        }
      end

      def custom_message_attributes compliance_check, object
        {source_objectid: object.objectid}
      end

      def message_attributes compliance_check, obj
        {
          test_id: compliance_check.origin_code,
          source_objectid: obj.objectid,
          source_object_path: object_path(compliance_check, obj)
        }.update(custom_message_attributes(compliance_check, obj))
      end

      def create_message_for_model compliance_check, model, status, message_attributes
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

      def label_attr(_compliance_check)
        :name
      end

      def lines_for _compliance_check, _model
        nil
      end

      def find_or_create_resources compliance_check, model
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

      def update_model_with_status compliance_check, model, status
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

      def metrics_key status
        {
          IGNORED: :uncheck_count,
          OK: :ok_count,
          WARNING: :warning_count,
          ERROR: :error_count
        }[status.to_sym]
      end
    end
  end
end