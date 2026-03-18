class EnablePgTrgmExtension < ActiveRecord::Migration[7.1]
  def change
    on_public_schema_only do
      enable_extension "pg_trgm"
    end
  end
end
