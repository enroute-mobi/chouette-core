class I18nObserver
	def i18n_locale_updated(_new_locale)
		Chouette::AreaType.reset_caches!
	end
end
