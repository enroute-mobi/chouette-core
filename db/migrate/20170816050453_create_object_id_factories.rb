class CreateObjectIdFactories < ActiveRecord::Migration
  def change
    create_table :object_id_factories do |t|

      t.timestamps null: false
    end
  end
end
