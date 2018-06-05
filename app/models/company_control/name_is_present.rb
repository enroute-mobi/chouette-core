module CompanyControl
  class NameIsPresent < InternalControl::Base
    def self.default_code; "3-Company-1" end

    def self.check compliance_check
      referential = compliance_check.referential
      referential.switch do
        referential.companies.each do |company|
          update_model_with_status compliance_check, company, status_ok_if(company.name.present?, compliance_check)
        end
      end
    end
  end
end
