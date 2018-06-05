module DummyControl
  class Dummy < InternalControl::Base
    store_accessor :control_attributes, :status

    enumerize :status, in: %i(OK ERROR WARNING IGNORED), default: :OK

    def self.default_code; "00-Dummy-00" end

    def self.check compliance_check
      dummy_status = compliance_check.control_attributes["status"]
      referential = compliance_check.referential
      referential.switch do
        referential.lines.each do |line|
          update_model_with_status compliance_check, line, dummy_status
        end
      end
    end
  end
end
