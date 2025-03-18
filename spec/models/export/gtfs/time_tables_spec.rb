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

RSpec.describe Export::Gtfs::Service do
  subject(:service) { Export::Gtfs::Service.new('test') }

  describe '==' do
    subject { service == other }

    context 'when the given Service has the same id' do
      let(:other) { Export::Gtfs::Service.new('test') }
      it { is_expected.to be_truthy }
    end

    context 'when the given Service has a different id' do
      let(:other) { Export::Gtfs::Service.new('other') }
      it { is_expected.to be_falsy }
    end

    context 'when the given Service is nil' do
      let(:other) { nil }
      it { is_expected.to be_falsy }
    end
  end

  describe '#extend_validity_period' do
    context 'when the Service has no validity period' do
      it 'sets to the validity period to the given period' do
        period = Period.parse('2030-01-01..2030-01-10')
        expect { service.extend_validity_period(period) }.to change(service, :validity_period).from(nil).to(period)
      end
    end

    context 'when the Service has the validity period "2030-01-10..2030-01-20"' do
      before { service.validity_period = Period.parse '2030-01-10..2030-01-20' }

      context 'when the period "2030-01-20..2030-01-30" is given' do
        let(:period) { Period.parse '2030-01-20..2030-01-30' }

        it do
          expect { service.extend_validity_period(period) }.to change(service, :validity_period)
            .to(Period.parse('2030-01-10..2030-01-30'))
        end
      end

      context 'when the date "2030-01-30" is given' do
        let(:date) { Date.parse '2030-01-30' }

        it do
          expect { service.extend_validity_period(date) }.to change(service, :validity_period)
            .to(Period.parse('2030-01-10..2030-01-30'))
        end
      end
    end
  end
end
