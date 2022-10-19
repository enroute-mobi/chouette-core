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
    end
  end
end
