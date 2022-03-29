class LocaleSelector
	def self.locale_for(context)
		LocaleSelector.new(context).locale
	end

	attr_reader :params, :session, :user

	def initialize(context)
		@params = context.params
		@session = context.session
		@user = context&.current_user
	end

	delegate :available_locales, :default_locale, to: I18n
  
  def request_locale
		supported_locale(params.try :[], 'lang')
  end
  
  def session_locale
		supported_locale(session.try :[], :language)
  end

	def user_locale
		supported_locale(user&.user_locale)
	end

  def locale
		request_locale || session_locale || user_locale || default_locale
  end

	private

	def supported_locale(value)
		value&.to_sym if available_locales.include?(value.to_sym)
	end
end
