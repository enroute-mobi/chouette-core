module CompanyControl
  class NameIsPresent < InternalControl::Base
    def self.default_code; "3-Company-1" end

    def self.object_path compliance_check, company
      line_referential_company_path(company.line_referential, company)
    end

    def self.collection referential
      Chouette::Company.where id: referential.lines.pluck(:company_id)
    end

    def self.compliance_test company
      company.name.present?
    end

    def self.message_attributes company
      {company_id: company.id}
    end
  end
end
