module CompanyControl
  class InternalBase < InternalControl::Base
    def self.object_path(compliance_check, company)
      workbench_line_referential_company_path(
        compliance_check.referential.workbench,
        company.line_provider.line_referential,
        company
      )
    end

    def self.collection_type(_)
      :companies
    end
  end
end
