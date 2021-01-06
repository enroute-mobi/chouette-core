class AddPublicCodeToStopArea < ActiveRecord::Migration[5.2]
  def change
    add_column :stop_areas, :public_code, :string
  end
end
