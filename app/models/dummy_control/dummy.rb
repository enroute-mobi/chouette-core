module DummyControl
  class Dummy < ComplianceControl
    enumerize :criticity, in: %i(error), scope: true, default: :error

    store_accessor :control_attributes, :status

    enumerize :status, in: %i(OK ERROR WARNING IGNORED), default: :OK

    def self.default_code; "00-Dummy-00" end

    def self.iev_enabled_check
      false
    end

    def self.resolve_compound_status status1, status2
      # Available statuses: (OK ERROR WARNING IGNORED)
      # XXX SPEC
      return [status1, status2].compact.last if status1.nil? || status2.nil?
      sorted_statuses = %w(IGNORED OK WARNING ERROR)
      sorted_statuses[[status1, status2].map{|k| sorted_statuses.index(k)}.max]
    end

    def self.metrics_key status
      {
        IGNORED: :uncheck_count,
        OK: :ok_count,
        WARNING: :warning_count,
        ERROR: :error_count
      }[status.to_sym]
    end

    def self.check compliance_check
      referential = compliance_check.referential
      dummy_status = compliance_check.control_attributes["status"]
      referential.switch do
        resources = compliance_check.compliance_check_set.compliance_check_resources
        unless resources.present?
          referential.lines.each do |line|
            compliance_check.compliance_check_set.compliance_check_resources.create do |res|
              res.resource_type = "line"
              res.name = line.name
            end
          end
        end

        resources.each do |res|
          res.metrics ||= {
            uncheck_count: 0,
            ok_count: 0,
            warning_count: 0,
            error_count: 0
          }
          iev_metrics = res.metrics["iev_metrics"]
          if iev_metrics
            iev_metrics = eval iev_metrics
          else
            iev_metrics = res.metrics.dup
            res.metrics["iev_metrics"] = iev_metrics
          end
          new_status = resolve_compound_status res.status, dummy_status
          metrics = res.metrics
          metrics[metrics_key(new_status)] = [iev_metrics[metrics_key(new_status)].to_i, 0].max + 1
          res.update! status: new_status, metrics: metrics
        end
      end
    end
  end
end
