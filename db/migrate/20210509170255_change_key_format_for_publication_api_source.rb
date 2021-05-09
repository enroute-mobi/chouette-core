class ChangeKeyFormatForPublicationApiSource < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      PublicationApiSource.joins(publication: :publication_setup).where('publication_setups.publish_per_line = true').each do |source|
        # Skip PublicationApiSource created with new code
        next if source.key.starts_with?("lines")

        new_key = "lines/#{source.key}.#{source.export&.user_file&.extension || 'zip'}"
        source.update_attribute :key, new_key
      end

      PublicationApiSource.joins(publication: :publication_setup).where('publication_setups.publish_per_line = false').each do |source|
        # Skip PublicationApiSource created with new code
        next if source.key.ends_with?(".zip")

        new_key = "#{source.key}.#{source.export&.user_file&.extension || 'zip'}"
        source.update_attribute :key, new_key
      end
    end
  end
end
