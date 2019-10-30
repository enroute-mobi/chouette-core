if InternalControl::Base.enabled?("dummy")
  module DummyControl
    class Dummy < InternalControl::Base
      store_accessor :control_attributes, :status

      store_accessor :control_attributes, :status

      enumerize :status, in: %i(OK ERROR WARNING IGNORED), default: :OK

      def self.default_code; "00-Dummy-00" end

      def self.object_path compliance_check, line
        line_referential_line_path(line.line_referential, line)
      end

      def self.compliance_test compliance_check, _
        %w(ignored ok).include? compliance_check.control_attributes["status"].downcase
      end

      def self.status_ok_if test, compliance_check
        compliance_check.control_attributes["status"]
      end
    end
  end
end
