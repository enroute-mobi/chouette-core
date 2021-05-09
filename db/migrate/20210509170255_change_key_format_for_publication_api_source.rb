class ChangeKeyFormatForPublicationApiSource < ActiveRecord::Migration[5.2]
  def change
    Destination::PublicationApi.joins(:publication_setup).where('publication_setups.publish_per_line = true').each do |destination|
      destination.publication_api.publication_api_sources.each do |publication_api_source|
        new_key = "lines/#{publication_api_source.key}.#{publication_api_source.export.user_file.extension}"
        publication_api_source.update_attribute(:key, new_key)
      end
    end

    Destination::PublicationApi.joins(:publication_setup).where('publication_setups.publish_per_line = false').each do |destination|
      destination.publication_api.publication_api_sources.each do |publication_api_source|
        new_key = "#{publication_api_source.key}.#{publication_api_source.export.user_file.extension}"
        publication_api_source.update_attribute(:key, new_key)
      end
    end
  end
end
