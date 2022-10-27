# frozen_string_literal: true

class RemoveLegacyControlCompanyNameIsPresent < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      ComplianceCheck.where(compliance_control_name: 'CompanyControl::NameIsPresent').destroy_all
      ComplianceControl.where(type: 'CompanyControl::NameIsPresent').delete_all
    end
  end

  def down; end
end
