# frozen_string_literal: true

RSpec.describe Export::Gtfs::TimeTables::Decorator do
  # TODO: Test each logic (only legacy specs have been adapted)

  context 'with one period' do
    let(:context) do
      Chouette::Factory.create do
        time_table dates_excluded: Time.zone.today, dates_included: Time.zone.tomorrow
      end
    end

    let(:time_table) { context.time_table }
    let(:decorator) { described_class.new time_table }

    it 'should return one period' do
      expect(decorator.periods.length).to eq 1
    end

    it 'should return two dates' do
      expect(decorator.dates.length).to eq 2
    end

    it 'should return a calendar with default service_id' do
      c = decorator.calendars
      expect(c.count).to eq 1
      expect(c.first[:service_id]).to eq decorator.default_service_id
    end

    it 'should return calendar_dates with correct service_id' do
      cd = decorator.calendar_dates
      expect(cd.count).to eq 2
      cd.each do |date|
        expect(date[:service_id]).to eq decorator.default_service_id
      end
    end
  end

  context 'with multiple periods' do
    let(:context) do
      Chouette::Factory.create do
        time_table periods: [Time.zone.today..Time.zone.today + 1, Time.zone.today + 3..Time.zone.today + 4]
      end
    end

    let(:time_table) { context.time_table }
    let(:decorator) { described_class.new time_table }

    it 'should return two periods' do
      expect(decorator.periods.length).to eq 2
    end

    it 'should return calendars with correct service_id' do
      allow(decorator).to receive(:default_service_id) { 'dummy' }
      c = decorator.calendars
      expect(c.count).to eq 2
      expect(c.first[:service_id]).to eq decorator.default_service_id
      expect(c.last[:service_id]).to eq "#{decorator.default_service_id}-#{time_table.periods.last.id}"
    end
  end
end
