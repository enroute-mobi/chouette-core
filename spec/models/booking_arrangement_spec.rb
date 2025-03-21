# frozen_string_literal: true

RSpec.describe BookingArrangement do
  it { is_expected.to_not validate_presence_of(:url) }
  it { is_expected.to_not validate_presence_of(:booking_url) }
end
