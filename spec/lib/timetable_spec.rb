RSpec.describe Timetable do

  def create(&block)
    Timetable::Builder.new.dsl(&block)
  end

  # TODO load a dedicated module ?
  def date(*definition)
    Timetable::Builder.date(*definition)
  end

  def date_range(*definition)
    Timetable::Builder.date_range(*definition)
  end

  def period(*definition)
    Timetable::Builder.period(*definition)
  end

  def days_of_week(definition)
    Timetable::Builder.days_of_week(definition)
  end

  describe "#limit!" do

    it "remove an included date not in the given range" do
      timetable = create { included_date "15/05" }
      timetable.limit! date_range("1/6","30/6")

      expect(timetable.included_dates).to be_empty
    end

    it "remove an excluded date not in the given range" do
      timetable = create { excluded_date "15/05" }
      timetable.limit! date_range("1/6","30/6")

      expect(timetable.excluded_dates).to be_empty
    end

    it "keeps an excluded date in the given range" do
      timetable = create { excluded_date "15/6" }

      expect do
        timetable.limit! date_range("1/6","30/6")
      end.to_not change(timetable, :excluded_dates)
    end

    it "keeps an included date in the given range" do
      timetable = create { included_date "15/6" }

      expect do
        timetable.limit! date_range("1/6","30/6")
      end.to_not change(timetable, :included_dates)
    end

    it "keeps a period included in the given range" do
      timetable = create { period "10/6", "20/6" }

      expect do
        timetable.limit! date_range("1/6","30/6")
      end.to_not change(timetable, :periods)
    end

    it "changes period start when not included in the given range" do
      timetable = create { period "15/5", "15/6" }

      expect do
        timetable.limit! date_range("1/6","30/6")
      end.to change(timetable, :first).from(date("15/05")).to(date("1/6"))

      timetable = create { period "1/12/2017", "15/1/2018" }

      expect do
        timetable.limit! date_range("1/1/2018","1/2/2018")
      end.to change(timetable, :first).to(date("1/1/2018"))
    end

    it "changes period end when not included in the given range" do
      timetable = create { period "15/6", "15/7" }

      expect do
        timetable.limit! date_range("1/6","30/6")
      end.to change(timetable, :last).from(date("15/7")).to(date("30/6"))
    end

    it "changes period start and end when not included in the given range" do
      timetable = create { period "1/5", "1/7" }
      timetable.limit! date_range("1/6","30/6")
      expect(timetable.periods).to match_array([period("1/6","30/6")])
    end

    it "remove a period not in the given range" do
      timetable = create { period "1/5", "15/5" }
      expect do
        timetable.limit! date_range("1/6","30/6")
      end.to change(timetable, :periods).to([])
    end

  end

  describe "#dup" do

    let(:timetable) do
      create do
        included_date "1/5"
        excluded_date "15/5"
        period "1/6", "30/6"
      end
    end

    let!(:duplicated) { timetable.dup }

    it "returns a new instance" do
      expect(duplicated).to_not be(timetable)
    end

    it "creates a duplicated timetable with its own periods" do
      expect do
        duplicated.periods.first.first = date("2/6")
      end.to_not change(timetable, :periods)
    end

  end

  describe "merge" do

    it "returns a new instance" do
      first = create {}
      second = create {}

      expect(first.merge(second)).to_not be(first)
    end

    it "merge included dates" do
      first = create { included_date "15/05" }
      second = create { included_date "16/05" }

      expect(first.merge(second).included_dates).to match_array([date("15/05"), date("16/05")])
    end

    it "merge excluded dates" do
      first = create { excluded_date "15/05" }
      second = create { excluded_date "16/05" }

      expect(first.merge(second).excluded_dates).to match_array([date("15/05"), date("16/05")])
    end

    it "merge periods" do
      first = create { period "1/6", "30/6" }
      second = create { period "1/7", "31/7" }

      expected_periods = [ period("1/6", "30/6"), period("1/7", "31/7") ]
      expect(first.merge(second).periods).to match_array(expected_periods)
    end

    it "avoid duplicates in included dates" do
      timetable = create { included_date "15/05" }
      expect(timetable.merge(timetable).included_dates).to match_array([date("15/05")])
    end

    it "avoid duplicates in excluded dates" do
      timetable = create { excluded_date "15/05" }
      expect(timetable.merge(timetable).excluded_dates).to match_array([date("15/05")])
    end

    it "avoid duplicates in periods" do
      timetable = create { period "15/05","16/05" }
      expect(timetable.merge(timetable).periods).to match_array([period("15/05","16/05")])
    end

  end

  describe "#limit" do

    it "apply limits given by several date ranges" do
      timetable = create { period("1/6", "30/6") }
      limited_timetable = timetable.limit([date_range("5/6","10/6"), date_range("15/6","20/6")])

      expect(limited_timetable.periods).to match_array([period("5/6","10/6"), period("15/6","20/6")])
    end

  end

  describe "#normalize!" do

    it "transforms single day period into an included date" do
      timetable = create { period "15/05","15/05" }
      expect do
        timetable.normalize!
      end.to change(timetable,:included_dates).to([date("15/05")]) and change(timetable,:period).to([])
    end

    it "remove empty period" do
      timetable = create { period "1/1/2030","1/1/2030", "L......" }
      expect do
        timetable.normalize!
      end.to change(timetable,:periods).to([]) and change(timetable,:empty?).to(true)
    end

    it 'removes excluded dates outside a period' do
      timetable = create do
        period '10/05', '20/05'
        excluded_date '09/05'
        excluded_date '21/05'
      end

      expect do
        timetable.normalize!
      end.to change(timetable, :excluded_dates).to([])
    end

    it 'removes excluded dates outside a period days of week' do
      timetable = create do
        period '10/05/2030', '20/05/2030', 'LT.TFSS'
        excluded_date '15/05/2030'
      end

      expect do
        timetable.normalize!
      end.to change(timetable, :excluded_dates).to([])
    end

    it 'removes included dates inside a period' do
      timetable = create do
        period '10/05', '20/05'
        included_date '15/05'
      end

      expect do
        timetable.normalize!
      end.to change(timetable, :included_dates).to([])
    end

    it 'removes included dates inside a period days of week' do
      timetable = create do
        period '10/05/2030', '20/05/2030', '..WT...'
        included_date '15/05/2030'
      end

      expect do
        timetable.normalize!
      end.to change(timetable, :included_dates).to([])
    end

    it 'removes included & excluded dates on the same date' do
      timetable = create do
        excluded_date '15/05'
        included_date '15/05'
      end

      expect do
        timetable.normalize!
      end.to change(timetable, :included_dates).to([]) and change(timetable, :excluded_dates).to([])
    end

    it 'removes fully excluded periods' do
      timetable = create do
        period '10/05/2030', '20/05/2030', '..W..S.'
        excluded_date '11/05/2030'
        excluded_date '15/05/2030'
        excluded_date '18/05/2030'
      end

      expect do
        timetable.normalize!
      end.to change(timetable, :periods).to([])
    end

    # Merge has been disabled in normalize!
    it "merge continuous periods", skip: true do
      timetable = create do
        period "1/06","10/06"
        period "11/06","19/06"
        period "20/06","30/06"
        period "10/06","20/06"
        period "2/06","29/06"
      end

      expect do
        timetable.normalize!
      end.to change(timetable,:periods).to([period("1/06","30/06")])
    end

    # Merge has been disabled in normalize!
    it "merge two distinct continuous periods", skip: true do
      timetable = create do
        # First
        period "1/06","10/06"
        period "11/06","19/06"
        period "20/06","30/06"
        period "10/06","20/06"
        period "2/06","29/06"

        # Second
        period "1/08","10/08"
        period "11/08","19/08"
        period "20/08","31/08"
        period "10/08","20/08"
        period "2/08","29/08"
      end

      expect do
        timetable.normalize!
      end.to change(timetable,:periods).to([period("1/06","30/06"), period("1/08","30/08")])
    end

  end

  describe '#uniq_days_of_week' do

    subject { timetable.uniq_days_of_week }

    context 'when no period is defined' do

      let(:timetable) { Timetable.new }

      it 'should be DaysOfWeek.none' do
        is_expected.to eq(Timetable::DaysOfWeek.none)
      end

    end

    context 'when a single period is defined' do

      let(:period_days_of_week) { days_of_week "L......" }
      let(:timetable) { create { period("1/06","30/06", "L......") } }

      it 'should be the DaysOfWeek of the period' do
        is_expected.to eq(period_days_of_week)
      end

    end

    context 'when several period are defined' do

      context 'with the same DaysOfWeek' do

        let(:shared_days_of_week) { days_of_week "L......" }

        let(:timetable) do
          create do
            period("1/06","15/06", "L......")
            period("1/07","15/07", "L......")
            period("1/08","15/08", "L......")
          end
        end

        it 'should be the DaysOfWeek shared by all periods' do
          is_expected.to eq(shared_days_of_week)
        end

      end

      context 'with different DaysOfWeeks' do

        let(:timetable) do
          create do
            period("1/06","15/06", 'L......')
            period("1/07","15/07", '.....S.')
            period("1/08","15/08", '......D')
          end
        end

        it { is_expected.to be_nil }

      end

    end

  end


end

RSpec.describe Timetable::Period do

  def date_range(*definition)
    Timetable::Builder.date_range(*definition)
  end

  def period(*definition)
    Timetable::Builder.period(*definition)
  end

  def self.date_range(*definition)
    Timetable::Builder.date_range(*definition)
  end

  def self.period(*definition)
    Timetable::Builder.period(*definition)
  end

  describe "#day_count" do
    context "without days of week" do
      it "returns the day between the first and last dates" do
        expect(period("1/1/2030", "1/1/2030").day_count).to eq(1)
        expect(period("1/1/2030", "7/1/2030").day_count).to eq(7)
      end
    end

    context "with days of week" do
      context "for a single day" do
        it "returns 0 if the single date isn't selected in the days of week" do
          expect(period("1/1/2030", "1/1/2030","L......").day_count).to eq(0)
        end

        it "returns 1 if the single date is selected in the days of week" do
          expect(period("1/1/2030", "1/1/2030",".M.....").day_count).to eq(1)
        end
      end

      context "for more than 1 day", skip: true do
        it "..." do
          expect(period("1/1/2030", "7/1/2030","..XX...").day_count).to eq(2)
          expect(period("1/1/2030", "7/1/2030",".....S.").day_count).to eq(1)
          expect(period("1/1/2030", "7/1/2030","xxxxxxx").day_count).to eq(7)
        end
      end
    end

  end

  describe "#intersects?" do

    it "true when the two periods share last and first" do
      expect(period("1/6", "10/6")).to be_intersect(period("10/6", "20/6"))
      expect(period("10/6", "20/6")).to be_intersect(period("1/6", "10/6"))
    end

    it "true when the period last is included in the other period" do
      expect(period("1/6", "15/6")).to be_intersect(period("10/6", "20/6"))
    end

    it "true when the period first is included in the other period" do
      expect(period("10/6", "20/6")).to be_intersect(period("1/6", "15/6"))
    end

    it "false when the two periods have not common dates" do
      expect(period("1/6","10/6")).to_not be_intersect(period("15/6", "25/6"))
      expect(period("15/6", "25/6")).to_not be_intersect(period("1/6","10/6"))
    end

    it "false when the period ends the day before the other period" do
      expect(period("1/6","10/6")).to_not be_intersect(period("11/6", "20/6"))
    end

    it "false when the period starts the day after the other period" do
      expect(period("11/6", "20/6")).to_not be_intersect(period("1/6","10/6"))
    end

  end

  describe "#continuous?" do

    it "true when the period ends the day before the other period" do
      expect(period("1/6","10/6")).to be_continuous(period("11/6", "20/6"))
    end

    it "true when the period starts the day after the other period" do
      expect(period("11/6", "20/6")).to be_continuous(period("1/6","10/6"))
    end

    it "true when the first period intersects the other" do
      expect(period("1/6", "15/6")).to be_continuous(period("10/6", "20/6"))
      expect(period("10/6", "20/6")).to be_continuous(period("1/6", "15/6"))
    end
  end

  describe "#merge!" do

    it "returns nil if the other period is nil"do
      expect(period("1/6","10/6").merge!(nil)).to be_nil
    end

    it "returns nil if the two periods don't have the same days_of_weeks (for the moment)" do
      expect(period("1/6","10/6","L......").merge!(period("10/6","20/6"))).to be_nil
      expect(period("1/6","10/6").merge!(period("10/6","20/6","L......"))).to be_nil
      expect(period("1/6","10/6","......S").merge!(period("10/6","20/6","L......"))).to be_nil
    end

    it "returns nil if the two periods aren't continuous"do
      expect(period("1/6","10/6").merge!(period("20/6","30/6"))).to be_nil
    end

    it "returns nil when the two periods have not common dates" do
      expect(period("1/6","10/6").merge!(period("15/6", "25/6"))).to be_nil
      expect(period("15/6", "25/6").merge!(period("1/6","10/6"))).to be_nil
    end

    context "when the two periods are continuous" do
      [
        [period("15/6","25/6"), period("20/6", "30/6"), date_range("15/6","30/6") ],
        [period("15/6","25/6"), period("25/6", "30/6"), date_range("15/6","30/6") ],
        [period("15/6","25/6"), period("10/6", "20/6"), date_range("10/6","25/6") ],
        [period("15/6","25/6"), period("10/6", "30/6"), date_range("10/6","30/6") ],
      ].each do |period, other, expected_range|
        it "changes #{period} when merged with #{other} to include #{expected_range}" do
          expect do
            period.merge!(other)
          end.to change(period, :date_range).to(expected_range)
        end
      end
    end

  end

end

RSpec.describe Timetable::Builder do

  alias builder subject

  describe "#included_date" do
    it "adds a included date from String definition" do
      builder.included_date "01/01/2030"
      expect(builder.timetable.included_dates).to match_array([Date.new(2030,1,1)])
    end
  end

  describe "#excluded_date" do
    it "adds a excluded date from String definition" do
      builder.excluded_date "01/01/2030"
      expect(builder.timetable.excluded_dates).to match_array([Date.new(2030,1,1)])
    end
  end

  describe "#period" do
    it "adds a period from two date String definitions" do
      builder.period "01/01/2030", "01/12/2030"
      expected_period = Timetable::Period.new(Date.new(2030,1,1), Date.new(2030,12,1))
      expect(builder.timetable.periods).to match_array([expected_period])
    end
  end

  # TODO load a dedicated module ?
  def days_of_week(*definition)
    Timetable::Builder.days_of_week(*definition)
  end

  describe ".days_of_week" do
    it "select all days with a letter" do
      expect(days_of_week("L......").days).to eq(%i{monday})
      expect(days_of_week("L.....S").days).to eq(%i{monday sunday})
      expect(days_of_week("L.W...S").days).to eq(%i{monday wednesday sunday})
      expect(days_of_week("X.X...X").days).to eq(%i{monday wednesday sunday})
    end
  end

end

RSpec.describe Timetable::DaysOfWeek do

  # TODO load a dedicated module ?
  def date(*definition)
    Timetable::Builder.date(*definition)
  end

  describe "#enable" do

    it "enable the given day" do
      expect { subject.enable(:monday) }.to change(subject, :days).to(%i{monday})
    end

    it "enable the given days" do
      expect { subject.enable(:monday, :sunday) }.to change(subject, :days).to(%i{monday sunday})
    end

    it "can be invoked via <<" do
      expect { subject << :monday << :sunday }.to change(subject, :days).to(%i{monday sunday})
    end

  end

  describe "#days" do

    it "returns a symbolic day list" do
      expect(Timetable::DaysOfWeek.all.days).to eq(%i(monday tuesday wednesday thursday friday saturday sunday))
    end

  end

  describe "#disable" do

    it "disable the given day" do
      subject.monday = true
      expect { subject.disable(:monday) }.to change(subject, :days).from(%i{monday}).to([])
    end

    it "disable the given days" do
      subject << :monday << :sunday
      expect { subject.disable(:monday, :sunday) }.to change(subject, :days).from(%i{monday sunday}).to([])
    end

    it "can be invoked via >>" do
      subject << :monday << :sunday
      expect { subject >> :monday >> :sunday }.to change(subject, :days).from(%i{monday sunday}).to([])
    end

  end

  describe "#match_date?" do

    let(:monday_date) { date("31/12/2029") }

    it "returns true if the given day has a selected day of week" do
      subject.enable(:monday)
      expect(subject.match_date?(monday_date)).to be_truthy
    end

    it "returns true if the given day has a selected day of week" do
      subject.enable(:sunday)
      expect(subject.match_date?(monday_date)).to be_falsy
    end

  end

  describe "#shift" do
    it "should shift by the correct amount" do
      expected = [[1, 0b010010000],
      [2, 0b100100000],
      [4, 0b010001000],
      [7, 0b001001000],
      [9, 0b100100000],
      [14, 0b001001000],
      ]

      expected.each do |e|
        days_of_week = Timetable::DaysOfWeek.new.enable(:tuesday, :friday)
        days_of_week.shift e.first
        expect(days_of_week.hash).to eq(e.last)
      end
    end
  end

end
