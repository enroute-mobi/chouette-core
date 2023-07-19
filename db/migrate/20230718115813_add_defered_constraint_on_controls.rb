class AddDeferedConstraintOnControls < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      remove_index :controls, name: :index_controls_position
      add_index :controls, %i[control_list_id control_context_id position], unique: true, name: 'index_controls_position'

      execute <<-SQL
        ALTER TABLE controls ADD CONSTRAINT index_controls_position UNIQUE USING INDEX index_controls_position DEFERRABLE INITIALLY DEFERRED;
      SQL
    end
  end

  def down
    on_public_schema_only do
      execute <<-SQL
        ALTER TABLE controls DROP CONSTRAINT index_controls_position;
      SQL
      add_index :controls, %i[control_list_id position], unique: true
    end
  end
end