class TimeZoneSelector
	def self.time_zone_for(cookies, user)
		TimeZoneSelector.new(cookies, user).time_zone
	end

	attr_reader :cookies, :user

	def initialize(cookies, user)
		@cookies = cookies
		@user = user
	end

	def browser_time_zone
		supported_time_zone(cookies.try(:[], 'browser.timezone'))
	end

	def user_time_zone
		supported_time_zone(user&.time_zone)
	end

	def default_time_zone
		Time.zone_default.name
	end

  def time_zone
		browser_time_zone || user_time_zone || default_time_zone
  end

	private

	def supported_time_zone value
		ActiveSupport::TimeZone.new(value)&.name
	rescue ArgumentError
	end
end
