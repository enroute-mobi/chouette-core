module DummyControl
  class Dummy < ComplianceControl
    enumerize :criticity, in: %i(error), scope: true, default: :error

    def self.default_code; "00-Dummy-00" end
  end
end
