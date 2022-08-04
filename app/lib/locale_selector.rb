class LocaleSelector
	def self.locale_for(params, session, user=nil)
		LocaleSelector.new.tap do |selector|
			selector.params = params
			selector.session = session
			selector.user = user
		end.locale
	end

	attr_accessor :params, :session, :user

	delegate :available_locales, :default_locale, to: I18n

  def request_locale
		supported_locale(params['lang'])
  end

  def session_locale
		supported_locale(session[:language])
  end

	def user_locale
		supported_locale(user&.user_locale)
	end

  def locale
		request_locale || session_locale || user_locale || default_locale
  end

	private

	def supported_locale(value)
		value&.to_sym if available_locales.include?(value&.to_sym)
	end
end
