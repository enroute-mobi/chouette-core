class UpdateExportGtfsBooleanValues < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      %w(prefer_referent_stop_area ignore_single_stop_station).each do |name|
        Export::Gtfs.where("options -> ? = '0'", name).update_all("options = options || hstore('#{name}', 'false')")
        Export::Gtfs.where("options -> ? = '1'", name).update_all("options = options || hstore('#{name}', 'true')")
      end
    end
  end

  def down
    on_public_schema_only do
      %w(prefer_referent_stop_area ignore_single_stop_station).each do |name|
        Export::Gtfs.where("options -> ? = 'false'", name).update_all("options = options || hstore(#{name}, '0')")
        Export::Gtfs.where("options -> ? = 'true'", name).update_all("options = options || hstore(#{name}, '1')")
      end
    end
  end
end
