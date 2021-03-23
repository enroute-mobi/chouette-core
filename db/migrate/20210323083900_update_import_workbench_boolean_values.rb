class UpdateImportWorkbenchBooleanValues < ActiveRecord::Migration[5.2]
  def up
    %w(automatic_merge archive_on_fail flag_urgent).each do |name|
      Import::Workbench.where("options ->> ? = '0'", name).update_all("options = jsonb_set(options, '{#{name}}', 'false')")
      Import::Workbench.where("options ->> ? = '1'", name).update_all("options = jsonb_set(options, '{#{name}}', 'true')")
    end
  end

  def down
    %w(automatic_merge archive_on_fail flag_urgent).each do |name|
      Import::Workbench.where("options ->> ? = 'false'", name).update_all("options = jsonb_set(options, '{#{name}}', '0')")
      Import::Workbench.where("options ->> ? = 'true'", name).update_all("options = jsonb_set(options, '{#{name}}', '1')")
    end
  end
end
