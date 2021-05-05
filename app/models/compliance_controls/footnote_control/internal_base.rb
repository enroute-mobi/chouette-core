module FootnoteControl
  class InternalBase < InternalControl::Base
    def self.object_path(compliance_check, footnote)
      referential_line_footnote(
        compliance_check.referential,
        footnote.line,
        footnote
      )
    end

    def self.collection_type(_)
      :footnotes
    end
  end
end
