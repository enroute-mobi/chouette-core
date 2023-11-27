# frozen_string_literal: true

class AddWorkbenchIdToCalendars < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table :calendars do |t|
        t.references :workbench, foreign_key: true
      end

      fill_workbench_id

      change_column :calendars, :workbench_id, :bigint, null: false
      remove_column :calendars, :workgroup_id
      remove_column :calendars, :organisation_id
    end
  end

  def down
    on_public_schema_only do
      change_table :calendars do |t|
        t.remove_references :workbench
        t.references :workgroup
        t.references :organisation
      end
    end
  end

  def fill_workbench_id
    ActiveRecord::Base.connection.execute(
      <<-SQL
        UPDATE "public"."calendars"
        SET "workbench_id" = "public"."workbenches"."id"
        FROM "public"."workbenches"
        WHERE "public"."workbenches"."workgroup_id" = "public"."calendars"."workgroup_id"
          AND "public"."workbenches"."organisation_id" = "public"."calendars"."organisation_id"
      SQL
    )
  end
end
