module LineControl
  class TransportMode < InternalControl::Base

    def self.default_code; "3-Line-4" end

    def self.object_path compliance_check, line
      referential_line_path(compliance_check.referential, line)
    end

    def self.collection_type(_)
      :lines
    end

    def self.label_attr(_)
      :published_name
    end

    def self.compliance_test compliance_check, line
      line.workgroup.transport_modes.keys.include?(line.transport_mode) && line.workgroup.transport_modes[line.transport_mode]&.include?(line.transport_submode)
    end

    def self.custom_message_attributes compliance_check, line
      {
        source_objectid: line.objectid,
        line_name: line.published_name,
        line_transport_mode: line.transport_mode,
        line_transport_submode: line.transport_submode
      }
    end
  end
end
