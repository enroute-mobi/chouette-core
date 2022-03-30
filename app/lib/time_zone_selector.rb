class TimeZoneSelector
	def self.time_zone_for(cookies, user)
		TimeZoneSelector.new.tap do |selector|
			selector.cookies = cookies
			selector.user = user
		end.time_zone
	end

	attr_accessor :cookies, :user

	# We chose not to use it for now because we need to figure out how to use value store in cookies
	# The goal is to use the value that was updated the last
	# Idea => set the cookie value as a JSON string (value, updated_at)
	def browser_time_zone
		supported_time_zone(cookies.try(:[], :'browser.timezone'))
	end

	def user_time_zone
		supported_time_zone(user&.time_zone)
	end

	def default_time_zone
		Time.zone_default.tzinfo.identifier
	end

  def time_zone
		user_time_zone || default_time_zone
  end

	private

	def supported_time_zone value
		ActiveSupport::TimeZone.new(value)&.tzinfo&.identifier
	rescue ArgumentError
	end
end
