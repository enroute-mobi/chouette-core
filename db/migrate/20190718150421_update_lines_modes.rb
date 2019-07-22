class UpdateLinesModes < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      Chouette::Line.where(transport_mode: nil).update_all transport_mode: "undefined"
      Chouette::Line.where(transport_submode: nil).update_all transport_submode: "undefined"
    end
  end
end
