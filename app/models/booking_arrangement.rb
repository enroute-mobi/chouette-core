class BookingArrangement < ApplicationModel
  include CodeSupport

  belongs_to :line_provider

  validates :name, presence: true
  validates :url, presence: true, url: { scheme: %w{http https} }
  validates :booking_url, presence: true, url: { scheme: %w{http https} }

  attribute :latest_booking_time, TimeOfDay::Type::TimeWithoutZone.new

  def latest_booking_time=(time_of_day)
    if time_of_day.is_a?(Hash) && time_of_day.keys == [1,2]
      time_of_day = TimeOfDay.new(time_of_day[1], time_of_day[2])
    end
    super time_of_day
  end

  extend Enumerize

  enumerize :booking_methods, in: [:call_driver, :call_office, :online, :phone_at_stop, :text_message, :mobile_app, :at_office, :other], multiple: true
  enumerize :booking_access, in: [:public, :authorised_public, :staff, :other]
  enumerize :book_when, in: [:until_previous_day, :day_of_travel_only, :advance_and_day_of_travel, :time_of_travel_only]
  enumerize :buy_when, in: [:on_reservation, :before_boarding, :on_boarding, :after_boarding, :on_checkout]

end