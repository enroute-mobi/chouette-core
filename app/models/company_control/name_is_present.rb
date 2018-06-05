module CompanyControl
  class NameIsPresent < InternalControl::Base
    def self.default_code; "3-Company-1" end

    def self.object_path compliance_check, company
      line_referential_company_path(company.line_referential, company)
    end

    def self.check compliance_check
      referential = compliance_check.referential
      referential.switch do
        referential.companies.each do |company|
          valid = company.name.present?
          status = status_ok_if(valid, compliance_check)
          update_model_with_status compliance_check, company, status
          unless valid
            create_message_for_model compliance_check, company, status, company_id: company.id
          end
        end
      end
    end
  end
end
