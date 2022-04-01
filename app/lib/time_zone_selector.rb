class TimeZoneSelector
	def self.time_zone_for(user)
		TimeZoneSelector.new.tap do |selector|
			selector.user = user
		end.time_zone
	end

	attr_accessor :user

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
