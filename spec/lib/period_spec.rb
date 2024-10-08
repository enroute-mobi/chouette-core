# frozen_string_literal: true

RSpec.describe Period do
  let(:date) { Time.zone.today }

  describe '.new' do
    %i[from to].each do |attribute|
      context "with #{attribute} attribute" do
        subject { Period.new(**{ attribute => value }) }

        [
          [Time.zone.today] * 2,
          ['01', Date.parse('01')],
          [:today, Time.zone.today],
          [:yesterday, Time.zone.yesterday],
          [:tomorrow, Time.zone.tomorrow]
        ].each do |value, expected_attribute|
          context "when is a #{value.class} #{value.inspect}" do
            let(:value) { value }
            it { is_expected.to have_attributes(**{ attribute => expected_attribute }) }
          end
        end
      end
    end
  end

  describe '#during' do
    subject { period.during(14.days) }

    context 'when the given duration is 14.days' do
      context 'when Period has a start date' do
        let(:period) { Period.from date }

        it { is_expected.to have_same_attributes(:from, than: period) }
        it { is_expected.to have_attributes(duration: 14.days) }
      end

      context 'when Period has only an end date' do
        let(:period) { Period.until date }

        it { is_expected.to have_same_attributes(:to, than: period) }
        it { is_expected.to have_attributes(duration: 14.days) }
      end
    end
  end

  describe '#valid?' do
    subject { period.valid? }

    context 'when from and to are not defined' do
      let(:period) { Period.new }
      it { is_expected.to be_falsy }
    end

    context 'when from and to are the same' do
      let(:period) { Period.new from: date, to: date }
      it { is_expected.to be_truthy }
    end

    context 'when from is before to' do
      let(:period) { Period.new from: date, to: date + 1 }
      it { is_expected.to be_truthy }
    end

    context 'when to is before from' do
      let(:period) { Period.new from: date, to: date - 1 }
      it { is_expected.to be_falsy }
    end
  end

  describe '#validate!' do
    subject { period.validate! }

    context 'when from and to are not defined' do
      let(:period) { Period.new }
      it {
        expect(subject.details).to eq({ from: [{ error: :invalid_bounds }],
                                        to: [{ error: :invalid_bounds }] })
      }
    end

    context 'when from and to are the same' do
      let(:period) { Period.new from: date, to: date }
      it {
        expect(subject.details).to be_empty
      }
    end

    context 'when from is before to' do
      let(:period) { Period.new from: date, to: date + 1 }
      it {
        expect(subject.details).to be_empty
      }
    end

    context 'when to is before from' do
      let(:period) { Period.new from: date, to: date - 1 }
      it {
        expect(subject.details).to eq({ from: [{ error: :to_before_from }],
                                        to: [{ error: :to_before_from }] })
      }
    end
  end

  describe '#empty?' do
    subject { period.empty? }

    context 'when from and to are not defined' do
      let(:period) { Period.new }
      it { is_expected.to be_truthy }
    end

    context 'when from is defined' do
      let(:period) { Period.new from: date }
      it { is_expected.to be_falsy }
    end

    context 'when to is defined' do
      let(:period) { Period.new to: date }
      it { is_expected.to be_falsy }
    end
  end

  describe '#day_count' do
    subject { period.day_count }

    context 'when from and to are the same day' do
      let(:period) { Period.new from: date, to: date }
      it { is_expected.to eq(1) }
    end

    context 'when from and to are two dates separated by 2 days (1..3)' do
      let(:period) { Period.new from: date, to: date + 2 }
      it { is_expected.to eq(3) }
    end

    context "when from isn't defined" do
      let(:period) { Period.until date }
      it { is_expected.to eq(Float::INFINITY) }
    end

    context "when to isn't defined" do
      let(:period) { Period.from date }
      it { is_expected.to eq(Float::INFINITY) }
    end

    context 'when to is before from' do
      let(:period) { Period.new from: date, to: date - 1 }
      it { is_expected.to be_zero }
    end
  end

  describe 'infinity_date_range', timezone: :random do
    subject { period.infinity_date_range }

    context 'when only the beginning date is defined (with) 2030-01-01)' do
      let(:period) { Period.from '2030-01-01' }
      it { is_expected.to have_attributes begin: Date.parse('2030-01-01'), end: Float::INFINITY }
    end

    context 'when only the end date is defined (with) 2030-01-01)' do
      let(:period) { Period.until '2030-01-01' }
      it { is_expected.to have_attributes begin: -Float::INFINITY, end: Date.parse('2030-01-01') }
    end

    context 'when the beginning date is is 2030-01-01 and the end date is 2030-12-31' do
      let(:period) { Period.new from: '2030-01-01', to: '2030-12-31' }
      it { is_expected.to have_attributes begin: Date.parse('2030-01-01'), end: Date.parse('2030-12-31') }
    end

    context 'when from and to are not defined' do
      let(:period) { Period.new }
      it { is_expected.to have_attributes begin: -Float::INFINITY, end: Float::INFINITY }
    end
  end

  describe '#time_range', timezone: :random do
    subject { period.time_range }

    context 'when only the beginning date is defined (with) 2030-01-01)' do
      let(:period) { Period.from '2030-01-01' }
      it { is_expected.to have_attributes begin: Time.zone.parse('2030-01-01 00:00'), end: nil }
    end

    context 'when only the end date is defined (with) 2030-01-01)' do
      let(:period) { Period.until '2030-01-01' }
      it { is_expected.to have_attributes begin: nil, end: Time.zone.parse('2030-01-02 00:00') }
    end

    context 'when the beginning date is is 2030-01-01 and the end date is 2030-12-31' do
      let(:period) { Period.new from: '2030-01-01', to: '2030-12-31' }
      it {
        is_expected.to have_attributes begin: Time.zone.parse('2030-01-01 00:00'),
                                       end: Time.zone.parse('2031-01-01 00:00')
      }
    end

    context 'when from and to are not defined' do
      let(:period) { Period.new }
      it { is_expected.to have_attributes begin: nil, end: nil }
    end
  end

  describe 'infinite_time_range', timezone: :random do
    subject { period.infinite_time_range }

    context 'when only the beginning date is defined (with) 2030-01-01)' do
      let(:period) { Period.from '2030-01-01' }
      it { is_expected.to have_attributes begin: Time.zone.parse('2030-01-01 00:00'), end: Float::INFINITY }
    end

    context 'when only the end date is defined (with) 2030-01-01)' do
      let(:period) { Period.until '2030-01-01' }
      it { is_expected.to have_attributes begin: -Float::INFINITY, end: Time.zone.parse('2030-01-02 00:00') }
    end

    context 'when the beginning date is is 2030-01-01 and the end date is 2030-12-31' do
      let(:period) { Period.new from: '2030-01-01', to: '2030-12-31' }
      it {
        is_expected.to have_attributes begin: Time.zone.parse('2030-01-01 00:00'),
                                       end: Time.zone.parse('2031-01-01 00:00')
      }
    end

    context 'when from and to are not defined' do
      let(:period) { Period.new }
      it { is_expected.to have_attributes begin: -Float::INFINITY, end: Float::INFINITY }
    end
  end

  describe 'include?' do
    subject { period.include? given_date }

    context 'when only the start date is defined' do
      let(:period) { Period.from date }

      context 'when the given date is the start date' do
        let(:given_date) { period.from }
        it { is_expected.to be_truthy }
      end
      context 'when the given date before the start date' do
        let(:given_date) { period.from - 1 }
        it { is_expected.to be_falsy }
      end
      context 'when the given date after the start date' do
        let(:given_date) { period.from + 1 }
        it { is_expected.to be_truthy }
      end
    end

    context 'when only the end date is defined' do
      let(:period) { Period.until date }

      context 'when the given date is the end date' do
        let(:given_date) { period.to }
        it { is_expected.to be_truthy }
      end
      context 'when the given date before the end date' do
        let(:given_date) { period.to - 1 }
        it { is_expected.to be_truthy }
      end
      context 'when the given date after the end date' do
        let(:given_date) { period.to + 1 }
        it { is_expected.to be_falsy }
      end
    end

    context 'when no stard or end dates are defined' do
      let(:period) { Period.new }

      let(:given_date) { date + rand }
      it { is_expected.to be_truthy }
    end

    context 'when the start and end dates are defined' do
      let(:period) { Period.from(date).during(3.days)  }

      context 'when the given date is the start date' do
        let(:given_date) { period.from }
        it { is_expected.to be_truthy }
      end
      context 'when the given date before the start date' do
        let(:given_date) { period.from - 1 }
        it { is_expected.to be_falsy }
      end
      context 'when the given date after the start date and before the end date' do
        let(:given_date) { period.from + 1 }
        it { is_expected.to be_truthy }
      end
      context 'when the given date is the end date' do
        let(:given_date) { period.to }
        it { is_expected.to be_truthy }
      end
      context 'when the given date after the end date' do
        let(:given_date) { period.to + 1 }
        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#limit' do
    subject { period.limit(date) }

    context "when period is '2030-01-01..2030-12-31'" do
      let(:period) { Period.parse '2030-01-01..2030-12-31' }
      [
        %w[2030-06-01 2030-06-01],
        %w[2020-01-01 2030-01-01],
        %w[2040-01-01 2030-12-31]
      ].each do |date, expected|
        context "when the given date is #{date}" do
          let(:date) { Date.parse(date) }
          it { is_expected.to eq(Date.parse(expected)) }
        end
      end
    end
  end

  describe '.parse' do
    subject { Period.parse definition }

    context "when definition is '2030-01-01..2030-12-31'" do
      let(:definition) { '2030-01-01..2030-12-31' }
      it { is_expected.to eq(Period.new(from: '2030-01-01', to: '2030-12-31')) }
    end

    context "when definition is '01-01..12-31'" do
      let(:definition) { '01-01..12-31' }
      it { is_expected.to eq(Period.new(from: '01-01', to: '12-31')) }
    end

    context "when definition is '01..15'" do
      let(:definition) { '01..15' }
      it { is_expected.to eq(Period.new(from: '01', to: '15')) }
    end

    context 'when definition is 01..15' do
      let(:definition) { 1..15 }
      it { is_expected.to eq(Period.new(from: '01', to: '15')) }
    end
  end

  describe '#mid_time' do
    subject { period.mid_time }

    context "when period is '2030-01-01..2030-01-01'" do
      let(:period) { Period.from('2030-01-01').during(1.day) }
      it { is_expected.to eq(Time.parse('2030-01-01 12:00')) }
    end

    context "when period is '2030-01-01..2030-01-02'" do
      let(:period) { Period.from('2030-01-01').during(2.days) }
      it { is_expected.to eq(Time.parse('2030-01-02 00:00')) }
    end

    context "when period is '2030-01-01..2030-01-03'" do
      let(:period) { Period.from('2030-01-01').during(3.days) }
      it { is_expected.to eq(Time.parse('2030-01-02 12:00')) }
    end
  end

  describe '.for_range' do
    subject { Period.for_range(range) }

    [
      [Range.new(nil, nil), nil],
      ['2022-06-07'.., Period.parse('2022-06-07..')],
      [Range.new(nil, '2022-06-07'), Period.parse('..2022-06-07')],
      ['2022-06-07'..'2022-06-17', Period.parse('2022-06-07..2022-06-17')],
      ['2022-06-07'...'2022-06-18', Period.parse('2022-06-07..2022-06-17')]
    ].each do |range, expected|
      context "when range is #{range.inspect}" do
        let(:range) do
          Range.new(
            range.begin&.to_date,
            range.end&.to_date,
            range.exclude_end?
          )
        end
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#beginless?' do
    [
      ['2030-01-01..2030-01-12', false],
      ['2030-01-01..', false],
      ['..2030-01-12', true]
    ].each do |definition, expected|
      context "when Period is #{definition}" do
        let(:period) { Period.parse definition }
        subject { period.beginless? }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#endless?' do
    [
      ['2030-01-01..2030-01-12', false],
      ['2030-01-01..', true],
      ['..2030-01-12', false]
    ].each do |definition, expected|
      context "when Period is #{definition}" do
        let(:period) { Period.parse definition }
        subject { period.endless? }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#to_postgresql_daterange' do
    [
      ['2030-01-01..2030-12-31', '[2030-01-01,2030-12-31]'],
      ['2030-01-01..', '[2030-01-01,infinity]'],
      ['..2030-12-31', '[-infinity,2030-12-31]'],
      ['..', '[-infinity,infinity]']
    ].each do |definition, expected|
      context "when Period is #{definition}" do
        let(:period) { Period.parse definition }
        subject { period.to_postgresql_daterange }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '.extend' do
    subject { period.extend(other) }

    [
      ['2030-06-01..2030-06-30', '2030-05-15..2030-06-15', '2030-05-15..2030-06-30'],
      ['2030-06-01..2030-06-30', '2030-06-15..2030-07-15', '2030-06-01..2030-07-15'],
      ['2030-06-01..2030-06-30', '2030-06-10..2030-06-20', '2030-06-01..2030-06-30'],
      ['2030-06-01..2030-06-30', '2030-05-01..2030-07-01', '2030-05-01..2030-07-01'],
      ['2030-06-01..2030-06-30', '2030-05-01..2030-05-31', '2030-05-01..2030-06-30'],
      ['2030-06-01..2030-06-30', '2030-07-01..2030-07-31', '2030-06-01..2030-07-31'],
      ['2030-06-01..', '2030-05-15..2030-06-15', '2030-05-15..'],
      ['2030-06-01..', '2030-06-15..2030-07-15', '2030-06-01..'],
      ['2030-06-01..', '2030-06-10..2030-06-20', '2030-06-01..'],
      ['2030-06-01..', '2030-05-01..2030-07-01', '2030-05-01..'],
      ['..2030-06-30', '2030-05-15..2030-06-15', '..2030-06-30'],
      ['..2030-06-30', '2030-06-15..2030-07-15', '..2030-07-15'],
      ['..2030-06-30', '2030-06-10..2030-06-20', '..2030-06-30'],
      ['..2030-06-30', '2030-05-01..2030-07-01', '..2030-07-01'],
      ['2030-06-01..2030-06-30', '2030-05-01..', '2030-05-01..'],
      ['2030-06-01..2030-06-30', '2030-06-15..', '2030-06-01..'],
      ['2030-06-01..2030-06-30', '2030-07-15..', '2030-06-01..']
    ].each do |period, other, expected|
      context "when Period is #{period}" do
        let(:period) { Period.parse period }

        context "when the given Period is #{other}" do
          let(:other) { Period.parse other }
          it { is_expected.to eq(Period.parse(expected)) }
        end
      end
    end
  end

  describe '.for_date' do
    subject { Period.for_date date }

    context 'when given date is 2030-01-01' do
      let(:date) { Date.parse('2030-01-01') }
      it { is_expected.to eq(Period.parse('2030-01-01..2030-01-01')) }
    end
  end

  describe '.for' do
    subject { Period.for value }

    context 'when given value is the Date "2030-01-01"' do
      let(:value) { Date.parse('2030-01-01') }
      it { is_expected.to eq(Period.parse('2030-01-01..2030-01-01')) }
    end

    context 'when given value is the Date range "2030-01-01..2030-01-31"' do
      let(:value) { Date.parse('2030-01-01')..Date.parse('2030-01-31') }
      it { is_expected.to eq(Period.parse('2030-01-01..2030-01-31')) }
    end

    context 'when given value is the Period "2030-01-01..2030-01-31"' do
      let(:value) { Period.parse('2030-01-01..2030-01-31') }
      it { is_expected.to eq(value) }
    end
  end
end

RSpec.describe Period::Type do
  subject(:type) { Period::Type.new }

  describe '#cast' do
    subject { type.cast(value) }
    [
      [nil, nil],
      ['[2022-06-07,)', Period.parse('2022-06-07..')],
      ['(,2022-06-07]', Period.parse('..2022-06-07')],
      ['[2022-06-07,2022-06-17]', Period.parse('2022-06-07..2022-06-17')],
      [Range.new(nil, nil), nil],
      [Range.new('2022-06-07', nil), Period.parse('2022-06-07..')],
      [Range.new(nil, '2022-06-07'), Period.parse('..2022-06-07')],
      [Range.new('2022-06-07', '2022-06-17'), Period.parse('2022-06-07..2022-06-17')],
      [{}, nil],
      [{ from: '2022-06-07' }, Period.parse('2022-06-07..')],
      [{ to: '2022-06-07' }, Period.parse('..2022-06-07')],
      [{ from: '2022-06-07', to: '2022-06-17' }, Period.parse('2022-06-07..2022-06-17')]
    ].each do |value, expected|
      context "when casted value is #{value.inspect}" do
        let(:value) { value }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#serialize' do
    subject { type.serialize(value) }
    [
      [Period.new, nil],
      [Period.parse('2022-06-07..'), Date.parse('2022-06-07')..Float::INFINITY],
      [Period.parse('..2022-06-07'), -Float::INFINITY..Date.parse('2022-06-07')],
      [Period.parse('2022-06-07..2022-06-17'), Date.parse('2022-06-07')..Date.parse('2022-06-17')]
    ].each do |value, expected|
      context "when serialized value is #{value.inspect}" do
        let(:value) { value }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
