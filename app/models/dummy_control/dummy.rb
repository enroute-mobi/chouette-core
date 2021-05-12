module DummyControl
  class Dummy < ComplianceControl
    include ComplianceControls::InternalControlInterface

    store_accessor :control_attributes, :status
    enumerize :status, in: %i(OK ERROR WARNING IGNORED), default: :OK

    def self.default_code; "00-Dummy-00" end

    def self.object_path _, line
      # FIXME See CHOUETTE-797
      redirect_line_path line
    end

    def self.compliance_test(compliance_check, _)
      %w(ignored ok).include? compliance_check.control_attributes["status"].downcase
    end

    def self.status_ok_if(_, compliance_check)
      compliance_check.control_attributes["status"]
    end
  end
end