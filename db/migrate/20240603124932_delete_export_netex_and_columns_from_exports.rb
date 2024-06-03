# frozen_string_literal: true

class DeleteExportNetexAndColumnsFromExports < ActiveRecord::Migration[5.2]
  def up # rubocop:disable Metrics/MethodLength
    on_public_schema_only do # rubocop:disable Metrics/BlockLength
      PublicationSetup.includes(
        publications: { export: {}, reports: {}, publication_api_sources: {} },
        destinations: { reports: {} }
      ) \
                      .where(['export_options @> hstore(?, ?)', 'type', 'Export::Netex']) \
                      .find_each(&:destroy)

      ActiveRecord::Base.connection.delete(
        <<-SQL
          DELETE FROM export_messages
          USING exports
          WHERE export_messages.export_id = exports.id
            AND exports.type = 'Export::Netex'
        SQL
      )
      ActiveRecord::Base.connection.delete(
        <<-SQL
          DELETE FROM exportables
          USING exports
          WHERE exportables.export_id = exports.id
            AND exports.type = 'Export::Netex'
        SQL
      )
      ActiveRecord::Base.connection.delete("DELETE FROM exports WHERE type = 'Export::Netex'")

      change_table :exports do |t|
        t.remove :token_upload
        t.remove :notified_parent_at
      end
    end
  end

  def down
    on_public_schema_only do
      change_table :exports do |t|
        t.string :token_upload
        t.datetime :notified_parent_at
      end
    end
  end
end
