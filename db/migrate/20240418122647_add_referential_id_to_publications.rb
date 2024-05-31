# frozen_string_literal: true

class AddReferentialIdToPublications < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      change_table :publications do |t|
        t.references :referential, foreign_key: true
      end

      connection.execute(
        <<~SQL
          UPDATE publications SET
            "referential_id" = (
              CASE "parent_type"
                WHEN 'Aggregate' THEN
                  (
                    SELECT aggregates.new_id
                    FROM aggregates
                    WHERE aggregates.id = publications.parent_id
                  )
              END
            )
        SQL
      )
    end
  end

  def down
    on_public_schema_only do
      change_table :publications do |t|
        t.remove :referential_id
      end
    end
  end
end
