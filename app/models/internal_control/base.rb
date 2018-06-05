module InternalControl
  class Base < ComplianceControl
    extend Rails.application.routes.url_helpers

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

    def self.check compliance_check
      referential = compliance_check.referential
      referential.switch do
        collection(referential).each do |obj|
          valid = compliance_test(obj)
          status = status_ok_if(valid, compliance_check)
          update_model_with_status compliance_check, obj, status
          unless valid
            create_message_for_model compliance_check, obj, status, message_attributes(obj)
          end
        end
      end
    end

    def self.resolve_compound_status status1, status2
      # Available statuses: (OK ERROR WARNING IGNORED)
      return [status1, status2].compact.last if status1.nil? || status2.nil?
      sorted_statuses = %w(IGNORED OK WARNING ERROR)
      sorted_statuses[[status1, status2].map{|k| sorted_statuses.index(k)}.max]
    end

    def self.status_ok_if test, compliance_check
      test ? "OK" : compliance_check.criticity.upcase
    end

    def self.message_key
      self.default_code.downcase.underscore
    end

    def self.resource_attributes compliance_check, model
      {
        label: model.send(label_attr),
        objectid: model.objectid,
        attribute: label_attr,
        object_path: object_path(compliance_check, model)
      }
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

    def self.label_attr
      :name
    end

    def self.find_or_create_resources compliance_check, model
      lines = [model] if model.is_a?(Chouette::Line)
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
        iev_metrics = resource.metrics["iev_metrics"]
        if iev_metrics
          iev_metrics = eval iev_metrics
        else
          iev_metrics = resource.metrics.dup
          resource.metrics["iev_metrics"] = iev_metrics
        end
        new_status = resolve_compound_status resource.status, status
        metrics = resource.metrics
        metrics[metrics_key(new_status)] = [iev_metrics[metrics_key(new_status)].to_i, 0].max + 1
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
