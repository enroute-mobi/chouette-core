module LineControl
  class Active < ComplianceControl
    include ComplianceControls::InternalControlInterface

    store_accessor :control_attributes, :duration

    validates_numericality_of :duration

    def initialize(*args)
      super
      self.duration ||= 5
    end

    def self.default_code; "3-Line-3" end

    def self.label_attr(_)
      :published_name
    end

    def self.compliance_test compliance_check, line
      from = Time.now.to_date
      to = compliance_check.duration&.to_i&.days&.from_now || from
      line.always_active_on_period?(from, to) || line.vehicle_journeys.empty?
    end

    def self.custom_message_attributes compliance_check, line
      {
        source_objectid: line.objectid,
        line_name: line.published_name
      }
    end
  end
end
