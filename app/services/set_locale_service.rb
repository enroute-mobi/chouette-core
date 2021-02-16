class SetLocaleService < ApplicationService
	include Wisper::Publisher

	def initialize(wanted_locale)
		@wanted_locale = wanted_locale
	end

	def call
		effective_locale = I18n.available_locales.include?(@wanted_locale) ? @wanted_locale : I18n.default_locale

    I18n.locale = effective_locale
    Rails.logger.info "Locale set to #{I18n.locale.inspect}"

    broadcast(:i18n_locale_updated, I18n.locale)
	end
end
