module LineControl
  class InternalBase < InternalControl::Base
    def self.object_path(compliance_check, line)
      referential_line_path(
        compliance_check.referential,
        line
      )
    end

    def self.collection_type(_)
      :lines
    end
  end
end
