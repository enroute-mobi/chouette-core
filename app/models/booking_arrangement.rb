# frozen_string_literal: true

class BookingArrangement < ApplicationModel
  include CodeSupport
  include LineReferentialSupport

  has_many :lines

  validates :name, presence: true
  validates :minimum_booking_period, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

  attribute :latest_booking_time, TimeOfDay::Type::TimeWithoutZone.new

  scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }

  def latest_booking_time=(time_of_day)
    time_of_day = TimeOfDay.from_input_hash(time_of_day).without_utc_offset if time_of_day.is_a?(Hash)

    super time_of_day
  end

  extend Enumerize

  enumerize :booking_methods,
            in: %i[call_driver call_office online phone_at_stop text_message mobile_app at_office other], multiple: true
  enumerize :booking_access, in: %i[public authorised_public staff other]
  enumerize :book_when, in: %i[until_previous_day day_of_travel_only advance_and_day_of_travel time_of_travel_only]
  enumerize :buy_when, in: %i[on_reservation before_boarding on_boarding after_boarding on_checkout]
end
