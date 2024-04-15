# frozen_string_literal: true

class AddOperationsColumnsToPublications < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/MethodLength
    on_public_schema_only do # rubocop:disable Metrics/BlockLength
      change_table :publications do |t|
        t.string :creator
        t.string :user_status
        t.string :error_uuid
      end

      connection.execute(
        <<~SQL
          UPDATE publications SET
            "status" = (
              CASE "status"
                WHEN 'new' THEN 'new'
                WHEN 'pending' THEN 'enqueued'
                WHEN 'successful' THEN 'done'
                WHEN 'failed' THEN 'done'
                WHEN 'running' THEN 'running'
                WHEN 'successful_with_warnings' THEN 'done'
              END
            ),
            "user_status" = (
              CASE "status"
                WHEN 'new' THEN 'pending'
                WHEN 'pending' THEN 'pending'
                WHEN 'successful' THEN 'successful'
                WHEN 'failed' THEN 'failed'
                WHEN 'running' THEN 'pending'
                WHEN 'successful_with_warnings' THEN 'warning'
              END
            )
        SQL
      )

      change_column :publications, :user_status, :string, null: false
    end
  end

  def down # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      connection.execute(
        <<~SQL
          UPDATE publications SET
            "status" = (
              CASE "status"
                WHEN 'new' THEN 'new'
                WHEN 'enqueued' THEN 'pending'
                WHEN 'running' THEN 'running'
                WHEN 'pending' THEN 'enqueued'
                WHEN 'done' THEN
                  CASE "user_status"
                  WHEN 'successful' THEN 'successful'
                  WHEN 'failed' THEN 'failed'
                  WHEN 'warning' THEN 'successful_with_warnings'
                END
              END
            )
        SQL
      )

      change_table :publications do |t|
        t.remove :creator_id
        t.remove :user_status
        t.remove :error_uuid
      end
    end
  end
end
