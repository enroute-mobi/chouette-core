class AddDeferedConstraintOnControls < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
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
    end
  end
end