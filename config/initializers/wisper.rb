Rails.application.config.to_prepare do
  Wisper.clear if Rails.env.development?

	SetLocaleService.subscribe(I18nObserver.new) # Add event listener to SetLocalService
end
