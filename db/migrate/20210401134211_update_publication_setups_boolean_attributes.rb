class UpdatePublicationSetupsBooleanAttributes < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      %w(prefer_referent_stop_area ignore_single_stop_station).each do |name|
        PublicationSetup.where("export_options -> ? = '0'", name).update_all("export_options = export_options || hstore('#{name}', 'false')")
        PublicationSetup.where("export_options -> ? = '1'", name).update_all("export_options = export_options || hstore('#{name}', 'true')")
      end
    end
  end

  def down
    on_public_schema_only do
      %w(prefer_referent_stop_area ignore_single_stop_station).each do |name|
        PublicationSetup.where("export_options -> ? = 'false'", name).update_all("export_options = export_options || hstore(#{name}, '0')")
        PublicationSetup.where("export_options -> ? = 'true'", name).update_all("export_options = export_options || hstore(#{name}, '1')")
      end
    end
  end
end
