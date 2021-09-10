RSpec.describe Period do
  let(:date) { Time.zone.today }

  describe "#during" do
    subject { period.during(14.days) }

    context "when the given duration is 14.days" do
      context "when Period has a start date" do
        let(:period) { Period.from date }

        it { is_expected.to have_same_attributes(:from, than: period) }
        it { is_expected.to have_attributes(day_count: 14) }
      end

      context "when Period has only an end date" do
        let(:period) { Period.until date }

        it { is_expected.to have_same_attributes(:to, than: period) }
        it { is_expected.to have_attributes(day_count: 14) }
      end
    end
  end

  describe "#valid?" do
    subject { period.valid? }

    context "when from and to are not defined" do
      let(:period) { Period.new }
      it { is_expected.to be_falsy }
    end

    context "when from and to are the same" do
      let(:period) { Period.new from: date, to: date }
      it { is_expected.to be_truthy }
    end

    context "when from is before to" do
      let(:period) { Period.new from: date, to: date+1 }
      it { is_expected.to be_truthy }
    end

    context "when to is before from" do
      let(:period) { Period.new from: date, to: date-1 }
      it { is_expected.to be_falsy }
    end
  end

  describe "#empty?" do
    subject { period.empty? }

    context "when from and to are not defined" do
      let(:period) { Period.new }
      it { is_expected.to be_truthy }
    end

    context "when from is defined" do
      let(:period) { Period.new from: date }
      it { is_expected.to be_falsy }
    end

    context "when to is defined" do
      let(:period) { Period.new to: date }
      it { is_expected.to be_falsy }
    end
  end

  describe "#day_count" do
    subject { period.day_count }

    context "when from and to are two dates separated by 3 days" do
      let(:period) { Period.new from: date, to: date+3 }
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

    context "when to is before from" do
      let(:period) { Period.new from: date, to: date-1 }
      it { is_expected.to be_zero }
    end
  end

  describe "#time_range" do
    subject { period.time_range }

    context "when only the beginning date is defined (with) 2030-01-01)" do
      let(:period) { Period.from Date.parse('2030-01-01') }
      it { is_expected.to have_attributes begin: DateTime.parse('2030-01-01 00:00'), end: nil }
    end

    context "when only the end date is defined (with) 2030-01-01)" do
      let(:period) { Period.until Date.parse('2030-01-01') }
      it { is_expected.to have_attributes begin: nil, end: DateTime.parse('2030-01-02 00:00') }
    end

    context "when the beginning date is is 2030-01-01 and the end date is 2030-12-31"  do
      let(:period) { Period.new from: Date.parse('2030-01-01'), to: Date.parse('2030-12-31') }
      it { is_expected.to have_attributes begin: DateTime.parse('2030-01-01 00:00'), end: DateTime.parse('2031-01-01 00:00') }
    end

    context "when from and to are not defined" do
      let(:period) { Period.new }
      it { is_expected.to  have_attributes begin: nil, end: nil}
    end
  end

  describe "infinite_time_range" do
    subject { period.infinite_time_range }

    context "when only the beginning date is defined (with) 2030-01-01)" do
      let(:period) { Period.from Date.parse('2030-01-01') }
      it { is_expected.to have_attributes begin: DateTime.parse('2030-01-01 00:00'), end: Float::INFINITY }
    end

    context "when only the end date is defined (with) 2030-01-01)" do
      let(:period) { Period.until Date.parse('2030-01-01') }
      it { is_expected.to have_attributes begin: -Float::INFINITY, end: DateTime.parse('2030-01-02 00:00') }
    end

    context "when the beginning date is is 2030-01-01 and the end date is 2030-12-31"  do
      let(:period) { Period.new from: Date.parse('2030-01-01'), to: Date.parse('2030-12-31') }
      it { is_expected.to have_attributes begin: DateTime.parse('2030-01-01 00:00'), end: DateTime.parse('2031-01-01 00:00') }
    end

    context "when from and to are not defined" do
      let(:period) { Period.new }
      it { is_expected.to have_attributes begin: -Float::INFINITY, end: Float::INFINITY }
    end
  end

  describe "include?" do
    subject { period.include? given_date }

    context "when only the start date is defined" do
      let(:period) { Period.from date }

      context "when the given date is the start date" do
        let(:given_date) { period.from }
        it { is_expected.to be_truthy }
      end
      context "when the given date before the start date" do
        let(:given_date) { period.from-1 }
        it { is_expected.to be_falsy }
      end
      context "when the given date after the start date" do
        let(:given_date) { period.from+1 }
        it { is_expected.to be_truthy }
      end
    end

    context "when only the end date is defined" do
      let(:period) { Period.until date }

      context "when the given date is the end date" do
        let(:given_date) { period.to }
        it { is_expected.to be_truthy }
      end
      context "when the given date before the end date" do
        let(:given_date) { period.to-1 }
        it { is_expected.to be_truthy }
      end
      context "when the given date after the end date" do
        let(:given_date) { period.to+1 }
        it { is_expected.to be_falsy }
      end
    end

    context "when no stard or end dates are defined" do
      let(:period) { Period.new }

      let(:given_date) { date + rand }
      it { is_expected.to be_truthy }
    end

    context "when the start and end dates are defined" do
      let(:period) { Period.from(date).during(3.days)  }

      context "when the given date is the start date" do
        let(:given_date) { period.from }
        it { is_expected.to be_truthy }
      end
      context "when the given date before the start date" do
        let(:given_date) { period.from-1 }
        it { is_expected.to be_falsy }
      end
      context "when the given date after the start date and before the end date" do
        let(:given_date) { period.from+1 }
        it { is_expected.to be_truthy }
      end
      context "when the given date is the end date" do
        let(:given_date) { period.to }
        it { is_expected.to be_truthy }
      end
      context "when the given date after the end date" do
        let(:given_date) { period.to+1 }
        it { is_expected.to be_falsy }
      end
    end
  end
end
