class TimeZoneSelector
	def self.time_zone_for(context)
		TimeZoneSelector.new(context).time_zone
	end

	attr_reader :cookies, :user

	def initialize(context)
		@user = context&.current_user
		@cookies = context.cookies
	end

	def request_time_zone
		supported_time_zone(cookies.try(:[], 'browser.timezone'))
	end

	def user_time_zone
		supported_time_zone(user&.time_zone)
	end

	def default_time_zone
		Time.zone_default.name
	end

  def time_zone
		request_time_zone || user_time_zone || default_time_zone
  end

	private

	def supported_time_zone value
		ActiveSupport::TimeZone.new(value)&.name
	rescue ArgumentError
	end
end
