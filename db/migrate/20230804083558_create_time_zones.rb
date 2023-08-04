class CreateTimeZones < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :time_zones do |t|
        t.string :name
        t.integer :utc_offset

        t.index [:name], unique: true
      end

      values = TZInfo::Timezone.all_identifiers.map do |name| 
        ['(', "'", name, "'", ',', ActiveSupport::TimeZone[name].utc_offset, ')'].join
      end.join(',')

      ActiveRecord::Base.connection.execute(
        <<~SQL
          INSERT INTO
            time_zones (name, utc_offset)
          VALUES
            #{values}
        SQL
      )
    end
  end
end
