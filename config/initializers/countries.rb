# frozen_string_literal: true

Rails.configuration.after_initialize do
  ISO3166.configure do |config|
    config.locales = (I18n.available_locales + Rails.configuration.stop_area_available_localizations).uniq
  end
end
