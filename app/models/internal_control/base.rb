module InternalControl
  class Base < ComplianceControl
    enumerize :criticity, in: %i(warning error), scope: true, default: :error

    def self.iev_enabled_check
      false
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

    def self.find_or_create_resource compliance_check, model
      compliance_check.compliance_check_set.compliance_check_resources.find_or_create_by(
        reference: model.objectid,
        resource_type: model.class.model_name.singular,
        name: model.name
      )
    end

    def self.update_model_with_status compliance_check, model, status
      resource = find_or_create_resource compliance_check, model
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
