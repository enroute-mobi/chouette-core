# frozen_string_literal: true

RSpec.describe Calendar, type: :model do
  include Support::TimeTableHelper

  it { should belong_to(:workbench).required(true) }
  it { should have_one(:workgroup).through(:workbench) }
  it { should have_one(:organisation).through(:workbench) }

  it { is_expected.to validate_presence_of(:name) }

  describe '#to_time_table' do
    let(:calendar) { create(:calendar, int_day_types: Calendar::MONDAY | Calendar::SUNDAY, date_ranges: [Date.today...(Date.today + 1.month)]) }

    it 'should convert calendar to an instance of Chouette::TimeTable' do
      time_table = calendar.convert_to_time_table
      expect(time_table).to be_an_instance_of(Chouette::TimeTable)
      expect(time_table.int_day_types).to eq calendar.int_day_types
      expect(time_table.periods[0].period_start).to eq(calendar.periods[0].begin)
      expect(time_table.periods[0].period_end).to eq(calendar.periods[0].end)

      expect(get_dates(time_table.dates, in_out: true)).to match_array(calendar.dates)
      expect(get_dates(time_table.dates, in_out: false)).to match_array(calendar.excluded_dates)
    end
  end

  describe 'application days' do
    let(:calendar) { create(:calendar) }
    it "should default to all days" do
      %w(monday tuesday wednesday thursday friday saturday sunday).each do |day|
        expect(calendar.send(day)).to be_truthy
      end
    end
  end

  describe 'validations' do
    it 'validates that dates and date_ranges do not overlap' do
      expect(build(:calendar, dates: [Date.today.beginning_of_week], date_ranges: [Date.today.beginning_of_week..Date.today])).to_not be_valid
    end

    it 'validates that dates and date_ranges do not overlap but allow for days not in the list' do
      expect(build(:calendar, dates: [Date.today.beginning_of_week - 1.week], date_ranges: [(Date.today.beginning_of_week - 1.week)..Date.today], int_day_types: Calendar::THURSDAY)).to be_valid
    end

    it 'validates that there are no duplicates in dates' do
      expect(build(:calendar, dates: [Date.yesterday, Date.yesterday], date_ranges: [Date.today..Date.tomorrow])).to_not be_valid
    end
  end

  describe 'before_validation' do
    let(:calendar) { create(:calendar, date_ranges: []) }

    it 'shoud fill date_ranges with date ranges' do
      expected_range = Date.today..Date.tomorrow
      calendar.date_ranges << expected_range
      calendar.valid?

      expect(calendar.date_ranges.map { |period| period.begin..period.end }).to eq([expected_range])
    end
  end

  describe "Update state" do
    def calendar_to_state calendar
      calendar.slice('id').tap do |item|
        item['comment'] = calendar.name
        item['day_types'] = "Di,Lu,Ma,Me,Je,Ve,Sa"
        item['current_month'] = calendar.month_inspect(Date.today.beginning_of_month)
        item['current_periode_range'] = Date.today.beginning_of_month.to_s
        item['time_table_periods'] = calendar.periods.map{|p| {'id': p.id, 'period_start': p.period_start.to_s, 'period_end': p.period_end.to_s}}
      end
    end

    subject(:calendar){ create :calendar }
    let(:state) { calendar_to_state subject }

    it 'should update time table periods association' do
      period = state['time_table_periods'].first
      period['period_start'] = (Date.today - 1.month).to_s
      period['period_end']   = (Date.today + 1.month).to_s

      subject.state_update state
      ['period_end', 'period_start'].each do |prop|
        expect(subject.reload.periods.first.send(prop).to_s).to eq(period[prop])
      end
    end

    it 'should create time table periods association' do
      state['time_table_periods'] << {
        'id' => false,
        'period_start' => (Date.today + 1.year).to_s,
        'period_end' => (Date.today + 2.year).to_s
      }

      expect {
        subject.state_update state
      }.to change {subject.periods.count}.by(1)
    end

    it 'should delete time table periods association' do
      state['time_table_periods'].first['deleted'] = true
      expect {
        subject.state_update state
      }.to change {subject.periods.count}.by(-1)
    end

    it 'should update name' do
      state['comment'] = "Edited timetable name"
      subject.state_update state
      expect(subject.reload.name).to eq state['comment']
    end

    it 'should update day_types' do
      state['day_types'] = "Di,Lu,Je,Ma"
      subject.state_update state
      expect(subject.reload.valid_days).to include(7, 1, 4, 2)
      expect(subject.reload.valid_days).not_to include(3, 5, 6)
    end

    it 'should delete date if date is set to neither include or excluded date' do
      updated = state['current_month'].map do |day|
        day['include_date'] = false if day['include_date']
      end

      expect {
        subject.state_update state
      }.to change {subject.dates.count}.by(-updated.compact.count)
    end

    it 'should update date if date is set to excluded date' do
        updated = state['current_month'].map do |day|
          next unless day['include_date']
          day['include_date']  = false
          day['excluded_date'] = true
          day
        end
        expect {
        subject.state_update state
      }.to change {subject.excluded_dates.count}.by(updated.compact.count)
    end

    it 'should create new include date' do
      day  = state['current_month'].find{|d| !d['excluded_date'] && !d['include_date'] }
      date = Date.parse(day['date'])
      day['include_date'] = true
      expect(subject.included_days).not_to include(date)

      expect {
        subject.state_update state
      }.to change {subject.dates.count}.by(1)
      expect(subject.reload.included_days).to include(date)
    end

    it 'should create new exclude date' do
      day  = state['current_month'].find{|d| !d['excluded_date'] && !d['include_date']}
      date = Date.parse(day['date'])
      day['excluded_date'] = true
      expect(subject.excluded_days).not_to include(date)

      expect {
        subject.state_update state
      }.to change {subject.all_dates.count}.by(1)
      expect(subject.reload.excluded_days).to include(date)
    end
  end

end
