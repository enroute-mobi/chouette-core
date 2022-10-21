# frozen_string_literal: true

class UpdateProcessingRuleType < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      ProcessingRule::Base
        .where(type: nil)
        .where.not(workgroup_id: nil)
        .update_all(type: 'ProcessingRule::Workgroup')

      ProcessingRule::Base
        .where(type: nil)
        .where.not(workbench_id: nil)
        .update_all(type: 'ProcessingRule::Workbench')

      change_column_null :processing_rules, :type, false
    end  
  end
end
