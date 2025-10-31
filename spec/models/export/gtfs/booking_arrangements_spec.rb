RSpec.describe Export::Gtfs::BookingArrangements::Decorator do
  let(:booking_arrangement) { BookingArrangement.new }
  let(:decorator) { described_class.new booking_arrangement }

  describe '#prior_notice_duration_min' do
    subject { decorator.prior_notice_duration_min }

    context 'when BookingArrangement#book_when is "advance_and_day_of_travel"' do
      before do
        booking_arrangement.book_when = 'advance_and_day_of_travel'
        booking_arrangement.minimum_booking_period = 60
      end

      it { is_expected.to eq(1) }
    end

    context 'when BookingArrangement#book_when is "time_of_travel_only"' do
      before { booking_arrangement.book_when = 'time_of_travel_only' }

      it { is_expected.to eq(nil) }
    end
  end

  describe '#prior_notice_last_day' do
    subject { decorator.prior_notice_last_day }
    context 'when BookingArrangement#latest_booking_time is present' do
      before { booking_arrangement.latest_booking_time = '01:00' }

      it { is_expected.to eq(1) }
    end

    context 'when BookingArrangement#latest_booking_time is not present' do
      it { is_expected.to eq(nil) }
    end
  end

  describe '#prior_notice_last_time' do
    subject { decorator.prior_notice_last_time }
    context 'when BookingArrangement#latest_booking_time is present' do
      before { booking_arrangement.latest_booking_time = '01:00' }

      it { is_expected.to eq('01:00:00') }
    end

    context 'when BookingArrangement#latest_booking_time is not present' do
      it { is_expected.to eq(nil) }
    end
  end

  describe '#booking_type' do
    subject { decorator.booking_type }
    context 'when BookingArrangement#book_when is "time_of_travel_only"' do
      before { booking_arrangement.book_when = 'time_of_travel_only' }

      it { is_expected.to eq(0) }
    end

    context 'when BookingArrangement#book_when is "advance_and_day_of_travel"' do
      before do
        booking_arrangement.book_when = 'advance_and_day_of_travel'
      end

      it { is_expected.to eq(1) }
    end

    context 'when BookingArrangement#book_when is "until_previous_day"' do
      before do
        booking_arrangement.book_when = 'until_previous_day'
      end

      it { is_expected.to eq(2) }
    end

    context 'when BookingArrangement#book_when is "day_of_travel_only"' do
      before do
        booking_arrangement.book_when = 'day_of_travel_only'
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe '#gtfs_attributes' do
    subject { decorator.gtfs_attributes }

    context 'when BookingArrangement#book_when is "advance_and_day_of_travel"' do
      before do
        booking_arrangement.book_when = 'advance_and_day_of_travel'
        booking_arrangement.booking_notes = 'test'
        booking_arrangement.phone = '0610253212'
        booking_arrangement.url = 'http://localhost'
        booking_arrangement.booking_url = 'http://localhost'
      end

      it {
        is_expected.to eq({
                            booking_rule_id: nil,
                            booking_type: 1,
                            message: 'test',
                            phone_number: '0610253212',
                            info_url: 'http://localhost',
                            booking_url: 'http://localhost',
                            prior_notice_duration_min: nil,
                            prior_notice_last_day: nil,
                            prior_notice_last_time: nil
                          })
      }
    end
  end
end
