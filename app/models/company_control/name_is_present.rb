module CompanyControl
  class NameIsPresent < ComplianceControl
    include ComplianceControls::InternalControlInterface

    only_with_custom_field Chouette::Company, :public_name

    def self.default_code; "3-Company-1" end

    def self.object_path(_, company)
      redirect_company_path(company)
    end

    def self.collection_type(_)
      :companies
    end

    def self.lines_for compliance_check, model
      compliance_check.referential.lines.where(company_id: model.id)
    end

    def self.compliance_test(_, company)
      company.custom_fields[:public_name]&.display_value.present?
    end
  end
end