# frozen_string_literal: true

RSpec.describe Chouette::TimeTable, type: :model do
  describe '.scheduled_on' do
    subject { referential.time_tables.scheduled_on(date) }

    let(:context) { Chouette.create { time_table periods: [] } }
    let(:time_table) { context.time_table }
    let(:referential) { context.referential }

    before { referential.switch }

    context 'when the given date is Tuesday 2030-01-15' do
      let(:date) { Date.parse '2030-01-15' }

      context 'when a Time Table has a matching Period "2030-01-10..2030-01-20"' do
        before { time_table.periods.create! range: Period.parse('2030-01-10..2030-01-20') }

        it { is_expected.to include(time_table) }

        context 'and a unmatching Period "2030-03-01..2030-03-30"' do
          before { time_table.periods.create! range: Period.parse('2030-03-01..2030-03-30') }
          it { is_expected.to include(time_table) }
        end

        context 'when a Time Table Days of Week includes only Sunday' do
          before { time_table.update days_of_week: Cuckoo::Timetable::DaysOfWeek.none.enable(:sunday) }
          it { is_expected.to_not include(time_table) }
        end

        context 'when a Time Table excludes the 2030-01-15' do
          before { time_table.dates.create! date: date, in_out: false }
          it { is_expected.to_not include(time_table) }
        end
      end

      context 'when a Time Table includes the 2030-01-15' do
        before { time_table.dates.create! date: date, in_out: true }
        it { is_expected.to include(time_table) }
      end
    end
  end
end

# DEPRECATED. Complete modern specs above

include Support::TimeTableHelper

RSpec.describe Chouette::TimeTable, :type => :model do
  subject(:time_table) { create(:time_table) }
  let(:subject_periods_to_range) { subject.periods.map{|p| p.period_start..p.period_end } }

  it { is_expected.to validate_presence_of :comment }
  it { is_expected.to validate_uniqueness_of :objectid }

  def create_time_table_periode time_table, start_date, end_date
    create(:time_table_period, time_table: time_table, :period_start => start_date, :period_end => end_date)
  end

  describe '#clean!' do
    let!(:vehicle_journey){ create :vehicle_journey }
    let!(:other_vehicle_journey){ create :vehicle_journey }
    let!(:other_time_table){ create :time_table }

    before(:each) do
      vehicle_journey.update time_tables: [time_table]
      other_vehicle_journey.update time_tables: [time_table, create(:time_table)]
    end

    it 'should clean all related assets' do
      expect(dates = time_table.dates).to be_present
      expect(periods = time_table.periods).to be_present
      expect(other_time_table.dates).to be_present
      expect(other_time_table.periods).to be_present

      Chouette::TimeTable.where(id: [time_table.id, create(:time_table).id]).clean!

      expect(Chouette::TimeTable.where(id: time_table.id)).to be_empty
      expect(Chouette::TimeTableDate.where(id: dates.map(&:id))).to be_empty
      expect(Chouette::TimeTablePeriod.where(id: periods.map(&:id))).to be_empty

      expect{ other_time_table.reload }.to_not raise_error
      expect(other_time_table.dates).to be_present
      expect(other_time_table.periods).to be_present

      expect(vehicle_journey.reload.time_tables.size).to eq 0
      expect(other_vehicle_journey.reload.time_tables.size).to eq 1
    end
  end

  describe "actualize" do
    let(:calendar) { create(:calendar) }
    let(:int_day_types) { 508 }

    before do
      subject.int_day_types = int_day_types
      subject.calendar = calendar
      subject.save
      subject.actualize
    end

    it 'should override dates' do
      expect(get_dates(subject.dates, in_out: true)).to match_array calendar.dates
      expect(get_dates(subject.dates, in_out: false)).to match_array calendar.excluded_dates
    end

    it 'should override periods' do
      [:period_start, :period_end].each do |key|
        expect(subject.periods.map(&key)).to match_array calendar.convert_to_time_table.periods.map(&key)
      end
    end

    it 'should not change int_day_types' do
      expect(subject.int_day_types).to eq(int_day_types)
    end
  end

  describe "Update state" do
    def time_table_to_state time_table
      time_table.slice('id').tap do |item|
        item['comment'] = time_table.comment
        item['color'] = time_table.color
        item['day_types'] = "Di,Lu,Ma,Me,Je,Ve,Sa"
        item['current_month'] = time_table.month_inspect(Time.zone.today.beginning_of_month)
        item['current_periode_range'] = Time.zone.today.beginning_of_month.to_s
        item['time_table_periods'] = time_table.periods.map{|p| {'id': p.id, 'period_start': p.period_start.to_s, 'period_end': p.period_end.to_s}}
      end
    end

    let(:state) { time_table_to_state subject }

    it 'should update time table periods association' do
      period = state['time_table_periods'].first
      period['period_start'] = (Time.zone.today - 1.month).to_s
      period['period_end']   = (Time.zone.today - 1.day).to_s

      subject.state_update state
      ['period_end', 'period_start'].each do |prop|
        expect(subject.reload.periods.first.send(prop).to_s).to eq(period[prop])
      end
    end

    it 'should create time table periods association' do
      state['time_table_periods'] << {
        'id' => false,
        'period_start' => (Time.zone.today + 1.year).to_s,
        'period_end' => (Time.zone.today + 2.year).to_s
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

    it 'should accept to delete a time table period and create a new one on the same period' do
      state['time_table_periods'].first['deleted'] = true
      state['time_table_periods'] << {
        'id' => false,
        'period_start' => (Time.zone.today + 1.year).to_s,
        'period_end' => (Time.zone.today + 2.year).to_s
      }
      expect {
        subject.state_update state
      }.to change {subject.periods.count}.by(0)
    end

    it 'should deny to create two time table periods on the same period' do
      state['time_table_periods'] += [{
        'id' => false,
        'period_start' => (Time.zone.today + 1.year).to_s,
        'period_end' => (Time.zone.today + 2.year).to_s
      },
      {
        'id' => false,
        'period_start' => (Time.zone.today + 1.year).to_s,
        'period_end' => (Time.zone.today + 2.year).to_s
      }]
      subject.state_update state

      invalid_periods = subject.periods.select{ |m| m.invalid? }
      expect(invalid_periods.count).to eq 2
      expect(invalid_periods.first.errors[:overlapped_periods]).not_to be_empty
    end

    it 'should deny to create one time table period on the same period than existing one' do

      state['time_table_periods'] << {
        'id' => false,
        'period_start' => state['time_table_periods'].first['period_start'],
        'period_end' => state['time_table_periods'].first['period_end']
      }
      subject.state_update state
      invalid_periods = subject.periods.select{ |m| m.invalid? }
      expect(invalid_periods.count).to eq 2
      expect(invalid_periods.first.errors[:overlapped_periods]).not_to be_empty
    end

    it 'should update calendar association' do
      subject.calendar = create(:calendar)
      subject.save
      state['calendar'] = nil

      subject.state_update state
      expect(subject.reload.calendar).to eq(nil)
    end

    it 'should update color' do
      state['color'] = '#FFA070'
      subject.state_update state
      expect(subject.reload.color).to eq(state['color'])
    end

    it 'should update comment' do
      state['comment'] = "Edited timetable name"
      subject.state_update state
      expect(subject.reload.comment).to eq state['comment']
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
        end

        subject.state_update state
        expect(subject.reload.dates.excluded.count).to eq (updated.compact.count)
    end

    it 'should create new include date' do
      day  = state['current_month'].find{|d| !d['excluded_date'] && !d['include_date'] }
      date = Date.parse(day['date'])
      day['include_date'] = true
      expect(subject.dates.included).not_to include(have_attributes(date: date))

      expect {
        subject.state_update state
      }.to change {subject.dates.count}.by(1)
      expect(subject.reload.dates.included).to include(have_attributes(date: date))
    end

    it 'should create new exclude date' do
      day  = state['current_month'].find{|d| !d['excluded_date'] && !d['include_date']}
      date = Date.parse(day['date'])
      day['excluded_date'] = true
      expect(subject.dates.excluded).not_to include(have_attributes(date: date))

      expect {
        subject.state_update state
      }.to change {subject.dates.count}.by(1)
      expect(subject.dates.excluded).to include(have_attributes(date: date))
    end
  end

  describe "#periods_max_date" do
    context "when all period extends from 04/10/2013 to 04/15/2013," do
      before(:each) do
        p1 = Chouette::TimeTablePeriod.new( :period_start => Date.strptime("04/10/2013", '%m/%d/%Y'), :period_end => Date.strptime("04/12/2013", '%m/%d/%Y'))
        p2 = Chouette::TimeTablePeriod.new( :period_start => Date.strptime("04/13/2013", '%m/%d/%Y'), :period_end => Date.strptime("04/15/2013", '%m/%d/%Y'))
        subject.periods = [ p1, p2]
        subject.save
      end

      it "should retreive 04/15/2013" do
        expect(subject.periods_max_date).to eq(Date.strptime("04/15/2013", '%m/%d/%Y'))
      end
      context "when 04/15/2013 is excluded, periods_max_dates selects the day before" do
        before(:each) do
          excluded_date = Date.strptime("04/15/2013", '%m/%d/%Y')
          subject.dates = [ Chouette::TimeTableDate.new( :date => excluded_date, :in_out => false)]
          subject.save
        end
        it "should retreive 04/14/2013" do
          expect(subject.periods_max_date).to eq(Date.strptime("04/14/2013", '%m/%d/%Y'))
        end
      end
      context "when day_types select only sunday and saturday," do
        before(:each) do
          # jeudi, vendredi
          subject.update(int_day_types: 2**(1+6) + 2**(1+7))
        end
        it "should retreive 04/14/2013" do
          expect(subject.periods_max_date).to eq(Date.strptime("04/14/2013", '%m/%d/%Y'))
        end
      end
      context "when day_types select only friday," do
        before(:each) do
          # jeudi, vendredi
          subject.update(int_day_types: 2**(1+6))
        end
        it "should retreive 04/12/2013" do
          expect(subject.periods_max_date).to eq(Date.strptime("04/13/2013", '%m/%d/%Y'))
        end
      end
      context "when day_types select only thursday," do
        before(:each) do
          # mardi
          subject.update(int_day_types: 2**(1+2))
        end
        it "should retreive 04/12/2013" do
          # 04/15/2013 is monday !
          expect(subject.periods_max_date).to be_nil
        end
      end
    end
  end

  describe 'update on periods and dates' do
    context "update days selection" do
        it "should update start_date and end_end" do
            days_hash = {}.tap do |hash|
                [ :monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday ].each { |d| hash[d] = false }
            end
            subject.update(days_hash)

            read = Chouette::TimeTable.find( subject.id )
            expect(read.start_date).to eq(read.dates.select{|d| d.in_out}.map(&:date).compact.min)
            expect(read.end_date).to eq(read.dates.select{|d| d.in_out}.map(&:date).compact.max)

        end
    end

    context 'add a new period' do
      let!(:new_start_date) { subject.start_date - 20.days }
      let!(:new_end_date) { subject.start_date - 1.day }
      let!(:new_period_attributes) do
        pa = periods_attributes
        pa['11111111111'] =
          { 'period_end' => new_end_date, 'period_start' => new_start_date, '_destroy' => '', 'id' => '',
            'time_table_id' => subject.id.to_s }
        pa
      end

      it 'should update start_date and end_end' do
        end_date = subject.end_date
        subject.update(periods_attributes: new_period_attributes)

        expect(subject.reload.start_date).to eq(new_start_date)
        expect(subject.reload.end_date).to eq(end_date)
      end
    end

    context 'update period end' do
      let!(:new_end_date) { subject.end_date + 20.days }
      let!(:new_period_attributes) do
        pa = periods_attributes
        pa['3']['period_end'] = new_end_date
        pa
      end
      it 'should update end_date' do
        subject.update(periods_attributes: new_period_attributes)

        expect(subject.reload.end_date).to eq(new_end_date)
      end
    end

    context 'update period start' do
      let!(:new_start_date) { subject.start_date - 20.days }
      let!(:new_period_attributes) do
        pa = periods_attributes
        pa['0'].merge! 'period_start' => new_start_date
        pa
      end
      it 'should update start_date' do
        subject.update(periods_attributes: new_period_attributes)

        expect(subject.reload.start_date).to eq(new_start_date)
      end
    end

    context 'remove periods and dates and add a new period' do
      let!(:new_start_date) { subject.start_date - 20.days }
      let!(:new_end_date) { subject.start_date - 1.days  }
      let!(:new_dates_attributes) do
        da = dates_attributes
        da.each { |_k, v| v.merge! '_destroy' => true }
        da
      end
      let!(:new_period_attributes) do
        pa = periods_attributes
        pa.each { |_k, v| v.merge! '_destroy' => true }
        pa['11111111111'] =
          { 'period_end' => new_end_date, 'period_start' => new_start_date, '_destroy' => '', 'id' => '',
            'time_table_id' => subject.id.to_s }
        pa
      end
      it 'should update start_date and end_date with new period added' do
        subject.update(periods_attributes: new_period_attributes, dates_attributes: new_dates_attributes)

        expect(subject.reload.start_date).to eq(new_start_date)
        expect(subject.reload.end_date).to eq(new_end_date)
      end
    end

    def dates_attributes
        {}.tap do |hash|
            subject.dates.each_with_index do |p, index|
                hash.merge! index.to_s => p.attributes.merge( "_destroy" => "" )
            end
        end
    end
    def periods_attributes
        {}.tap do |hash|
            subject.periods.each_with_index do |p, index|
                hash.merge! index.to_s => p.attributes.merge( "_destroy" => "" )
            end
        end
    end
  end

  describe "#periods_min_date" do
    context "when all period extends from 04/10/2013 to 04/15/2013," do
      before(:each) do
        p1 = Chouette::TimeTablePeriod.new( :period_start => Date.strptime("04/10/2013", '%m/%d/%Y'), :period_end => Date.strptime("04/12/2013", '%m/%d/%Y'))
        p2 = Chouette::TimeTablePeriod.new( :period_start => Date.strptime("04/13/2013", '%m/%d/%Y'), :period_end => Date.strptime("04/15/2013", '%m/%d/%Y'))
        subject.periods = [ p1, p2]
        subject.save
      end

      it "should retreive 04/10/2013" do
        expect(subject.periods_min_date).to eq(Date.strptime("04/10/2013", '%m/%d/%Y'))
      end
      context "when 04/10/2013 is excluded, periods_min_dates select the day after" do
        before(:each) do
          excluded_date = Date.strptime("04/10/2013", '%m/%d/%Y')
          subject.dates = [ Chouette::TimeTableDate.new( :date => excluded_date, :in_out => false)]
          subject.save
        end
        it "should retreive 04/11/2013" do
          expect(subject.periods_min_date).to eq(Date.strptime("04/11/2013", '%m/%d/%Y'))
        end
      end
      context "when day_types select only tuesday and friday," do
        before(:each) do
          # jeudi, vendredi
          subject.update(int_day_types: 2**(1+4) + 2**(1+5))
        end
        it "should retreive 04/11/2013" do
          expect(subject.periods_min_date).to eq(Date.strptime("04/11/2013", '%m/%d/%Y'))
        end
      end
      context "when day_types select only friday," do
        before(:each) do
          # jeudi, vendredi
          subject.update(int_day_types: 2**(1+5))
        end
        it "should retreive 04/12/2013" do
          expect(subject.periods_min_date).to eq(Date.strptime("04/12/2013", '%m/%d/%Y'))
        end
      end
      context "when day_types select only thursday," do
        before(:each) do
          # mardi
          subject.update(int_day_types: 2**(1+2))
        end
        it "should retreive 04/12/2013" do
          # 04/15/2013 is monday !
          expect(subject.periods_min_date).to be_nil
        end
      end
    end
  end
  describe "#periods.build" do
    it "should add a new instance of period, and periods_max_date should not raise error" do
      period = subject.periods.build
      subject.periods_max_date
      expect(period.period_start).to be_nil
      expect(period.period_end).to be_nil
    end
  end

  describe "#periods" do

    context "when a period is added," do
      let!(:time_table) {
        create(:time_table, :empty) do |time_table|
          time_table.periods.create( :period_start => Time.zone.today, :period_end => Time.zone.today + 3.days)
        end
      }

      it "should update shortcut" do
        time_table.periods << build(:time_table_period, time_table: time_table, :period_start => Time.zone.today + 4.days, :period_end => Time.zone.today + 6.days)
        time_table.save
        expect(time_table.start_date).to eq(Time.zone.today)
        expect(time_table.end_date).to eq(Time.zone.today + 6.days)
      end
    end

    context "when a period is removed," do
      let!(:time_table) {
        create(:time_table, :empty) do |time_table|
          time_table.periods.create( :period_start => Time.zone.today, :period_end => Time.zone.today + 3.days)
          time_table.periods.create( :period_start => Time.zone.today + 4.days, :period_end => Time.zone.today + 6.days)
        end
      }

      it "should update shortcut" do
        time_table.periods = [ build( :time_table_period, :period_start => Time.zone.today + 4.days, :period_end => Time.zone.today + 6.days, time_table: time_table) ]
        time_table.save
        expect(time_table.reload.start_date).to eq(Time.zone.today + 4.days)
        expect(time_table.reload.end_date).to eq(Time.zone.today + 6.days)
      end
    end

    context "when a period is updated," do
      let!(:time_table) {
        create(:time_table, :empty) do |time_table|
          time_table.periods.create( :period_start => Time.zone.today, :period_end => Time.zone.today + 3.days)
        end
      }

      it "should update shortcut" do
        first_period = time_table.periods.first
        first_period.period_start = Time.zone.today - 1.day
        first_period.period_end = Time.zone.today + 5.days
        time_table.save
        expect(time_table.start_date).to eq( Time.zone.today - 1.day)
        expect(time_table.end_date).to eq(Time.zone.today + 5.days)
      end
    end

  end

  describe "#periods.valid?" do
    context "when an empty period is set," do
      it "should not save tm if period invalid" do
        subject = Chouette::TimeTable.new({"comment"=>"test",
                                           "monday"=>"0",
                                           "tuesday"=>"0",
                                           "wednesday"=>"0",
                                           "thursday"=>"0",
                                           "friday"=>"0",
                                           "saturday"=>"0",
                                           "sunday"=>"0",
                                           "objectid"=>"",
                                           "periods_attributes"=>{"1397136188334"=>{"period_start"=>"",
                                           "period_end"=>"",
                                           "_destroy"=>""}}})
        subject.save
        expect(subject.id).to be_nil
      end
    end
    context "when a valid period is set," do
      it "it should save tm if period valid" do
        subject = Chouette::TimeTable.new({"comment"=>"test",
                                           "monday"=>"1",
                                           "tuesday"=>"1",
                                           "wednesday"=>"1",
                                           "thursday"=>"1",
                                           "friday"=>"1",
                                           "saturday"=>"1",
                                           "sunday"=>"1",
                                           "objectid"=>"",
                                           "periods_attributes"=>{"1397136188334"=>{"period_start"=>"2014-01-01",
                                           "period_end"=>"2015-01-01",
                                           "_destroy"=>""}}})
        subject.save
        tm = Chouette::TimeTable.find subject.id
        expect(tm.periods.empty?).to be_falsey
        expect(tm.start_date).to eq(Date.new(2014, 01, 01))
        expect(tm.end_date).to eq(Date.new(2015, 01, 01))

      end
    end
  end

  describe "#dates" do
    let(:timetable) { create(:time_table, :empty)}

    context "when a date is added," do
      before(:each) do
        timetable.dates << Chouette::TimeTableDate.new( :date => Time.zone.today, :in_out => true)
        timetable.save
      end
      it "should update shortcut" do
        expect(timetable.start_date).to eq(Time.zone.today)
        expect(timetable.end_date).to eq(Time.zone.today)
      end
    end

    context "when a date is removed," do
      before(:each) do
        timetable.dates << Chouette::TimeTableDate.new( :date => Time.zone.today, :in_out => true)
        timetable.dates << Chouette::TimeTableDate.new( :date => Time.zone.today + 1, :in_out => true)
        subject.save
      end
      it "should update shortcut" do
        timetable.dates = [ Chouette::TimeTableDate.new( :date => Time.zone.today + 1, :in_out => true) ]
        timetable.save
        expect(timetable.start_date).to eq(Time.zone.today + 1)
        expect(timetable.end_date).to eq(Time.zone.today + 1)
      end
    end

    context "when all the dates and periods are removed," do
      it "should update shortcut" do
        expect(timetable.start_date).to be_nil
        expect(timetable.end_date).to be_nil
      end
    end

    context "when a date is updated," do
      before(:each) do
        timetable.dates << Chouette::TimeTableDate.new( :date => Time.zone.today, :in_out => true)
        timetable.save
      end

      it "should update shortcut" do
        timetable.dates.first.date = Time.zone.today + 5.day
        timetable.save
        expect(timetable.reload.start_date).to eq(Time.zone.today + 5.day)
        expect(timetable.reload.end_date).to eq(Time.zone.today + 5.day)
      end
    end
  end
  describe "#dates.valid?" do
    it "should not save tm if date invalid" do
      subject = Chouette::TimeTable.new({"comment"=>"test",
                                         "monday"=>"0",
                                         "tuesday"=>"0",
                                         "wednesday"=>"0",
                                         "thursday"=>"0",
                                         "friday"=>"0",
                                         "saturday"=>"0",
                                         "sunday"=>"0",
                                         "objectid"=>"",
                                         "dates_attributes"=>{"1397136189216"=>{"date"=>"",
                                         "_destroy"=>"", "in_out" => true}}})
      subject.save
      expect(subject.id).to be_nil
    end
    it "it should save tm if date valid" do
      subject = Chouette::TimeTable.new({"comment"=>"test",
                                         "monday"=>"1",
                                         "tuesday"=>"1",
                                         "wednesday"=>"1",
                                         "thursday"=>"1",
                                         "friday"=>"1",
                                         "saturday"=>"1",
                                         "sunday"=>"1",
                                         "objectid"=>"",
                                         "dates_attributes"=>{"1397136189216"=>{"date"=>"2015-01-01",
                                         "_destroy"=>"", "in_out" => true}}})
      subject.save
      tm = Chouette::TimeTable.find subject.id
      expect(tm.dates.empty?).to be_falsey
      expect(tm.start_date).to eq(Date.new(2015, 01, 01))
      expect(tm.end_date).to eq(Date.new(2015, 01, 01))
    end
  end

  describe "#valid_days" do
    it "should begin with position 0" do
      subject.int_day_types = 128
      expect(subject.valid_days).to eq([6])
    end
  end

  describe "valid_day?" do
    it "should work properly" do
      subject.int_day_types = ApplicationDaysSupport::SUNDAY
      expect(subject.valid_day?(1)).to be_falsy
      expect(subject.valid_day?(0)).to be_truthy
      expect(subject.valid_day?(7)).to be_truthy
      expect(subject.valid_day?(Time.now.beginning_of_week - 1.day)).to be_truthy
      subject.int_day_types = ApplicationDaysSupport::MONDAY
      expect(subject.valid_day?(1)).to be_truthy
      expect(subject.valid_day?(0)).to be_falsy
      expect(subject.valid_day?(Time.now.beginning_of_week)).to be_truthy
    end
  end

  describe "#include_day?" do
    it "should return true if a date equal day" do
      time_table = Chouette::TimeTable.create!(:comment => "Test", :objectid => "test:Timetable:1:loc")
      time_table.dates << Chouette::TimeTableDate.new( :date => Time.zone.today, :in_out => true)
      expect(time_table.include_day?(Time.zone.today)).to eq(true)
    end

    it "should return true if a period include day" do
      time_table = Chouette::TimeTable.create!(:comment => "Test", :objectid => "test:Timetable:1:loc", :int_day_types => 12) # Day type monday and tuesday
      time_table.periods << Chouette::TimeTablePeriod.new(
                              :period_start => Date.new(2013, 05, 27),
                              :period_end => Date.new(2013, 05, 29))
      expect(time_table.include_day?( Date.new(2013, 05, 27))).to eq(true)
    end
  end

  describe "#include_in_dates?" do
    it "should return true if a date equal day" do
      time_table = Chouette::TimeTable.create!(:comment => "Test", :objectid => "test:Timetable:1:loc")
      time_table.dates << Chouette::TimeTableDate.new( :date => Time.zone.today, :in_out => true)
      expect(time_table.include_in_dates?(Time.zone.today)).to eq(true)
    end

    it "should return false if a period include day  but that is exclued" do
      time_table = Chouette::TimeTable.create!(:comment => "Test", :objectid => "test:Timetable:1:loc", :int_day_types => 12) # Day type monday and tuesday
      excluded_date = Date.new(2013, 05, 27)
      time_table.dates << Chouette::TimeTableDate.new( :date => excluded_date, :in_out => false)
      expect(time_table.include_in_dates?( excluded_date)).to be_falsey
    end
  end

  describe "#include_in_periods?" do
    it "should return true if a period include day" do
      time_table = Chouette::TimeTable.create!(:comment => "Test", :objectid => "test:Timetable:1:loc", :int_day_types => 4)
      time_table.periods << Chouette::TimeTablePeriod.new(
                              :period_start => Date.new(2012, 1, 1),
                              :period_end => Date.new(2012, 01, 30))
      expect(time_table.include_in_periods?(Date.new(2012, 1, 2))).to eq(true)
    end

    it "should return false if a period include day  but that is exclued" do
      time_table = Chouette::TimeTable.create!(:comment => "Test", :objectid => "test:Timetable:1:loc", :int_day_types => 12) # Day type monday and tuesday
      excluded_date = Date.new(2013, 05, 27)
      time_table.dates << Chouette::TimeTableDate.new( :date => excluded_date, :in_out => false)
      time_table.periods << Chouette::TimeTablePeriod.new(
                              :period_start => Date.new(2013, 05, 27),
                              :period_end => Date.new(2013, 05, 29))
      expect(time_table.include_in_periods?( excluded_date)).to be_falsey
    end
  end

  describe "#bounding_dates" do
    context "when timetable contains only periods" do
      before do
        subject.dates = []
        subject.save
      end
      it "should retreive periods.period_start.min and periods.period_end.max" do
        expect(subject.bounding_dates.min).to eq(subject.periods.map(&:period_start).min)
        expect(subject.bounding_dates.max).to eq(subject.periods.map(&:period_end).max)
      end
    end

    context "when timetable contains only dates" do
      before do
        subject.periods = []
        subject.save
      end
      it "should retreive dates.min and dates.max" do
        expect(subject.bounding_dates.min).to eq(subject.dates.map(&:date).min)
        expect(subject.bounding_dates.max).to eq(subject.dates.map(&:date).max)
      end
    end

    it "should contains min date" do
      min_date = subject.bounding_dates.min
      subject.dates.each do |tm_date|
        expect(min_date <= tm_date.date).to be_truthy
      end
      subject.periods.each do |tm_period|
        expect(min_date <= tm_period.period_start).to be_truthy
      end

    end

    it "should contains max date" do
      max_date = subject.bounding_dates.max
      subject.dates.each do |tm_date|
        expect(tm_date.date <= max_date).to be_truthy
      end
      subject.periods.each do |tm_period|
        expect(tm_period.period_end <= max_date).to be_truthy
      end

    end
  end

  describe "#periods" do
    let(:time_table) { create(:time_table, :empty) }

    it "should have period_start before period_end" do
      period = build(:time_table_period, time_table: time_table, period_start: Time.zone.today, period_end: Time.zone.today + 10)
      expect(period.valid?).to be_truthy
    end
    it "should not have period_start after period_end" do
      period = build(:time_table_period, time_table: time_table, period_start: Time.zone.today, period_end: Time.zone.today - 10)
      expect(period.valid?).to be_falsey
    end
    it "should not have period_start equal to period_end" do
      period = build(:time_table_period, time_table: time_table, period_start: Time.zone.today, period_end: Time.zone.today)
      expect(period.valid?).to be_falsey
    end
  end

  describe 'checksum' do
    let(:checksum_owner) { create(:time_table) }

    it_behaves_like 'checksum support'

    it_behaves_like 'it works with both checksums modes',
                    "changes when a vjas is created",
                    ->{
                      checksum_owner.update_checksum!
                    },
                    change: false,
                    more: ->{
                      expect(checksum_owner.dates.count).to eq 1
                      expect(checksum_owner.periods.count).to eq 1
                    } do
                      let(:checksum_owner) {
                        checksum_owner = build(:time_table)
                        checksum_owner.periods.build period_start: Time.now, period_end: 10.days.from_now
                        checksum_owner.dates.build date: Time.now
                        checksum_owner.save!
                        checksum_owner
                      }
                    end

    it_behaves_like 'it works with both checksums modes',
                    'changes when a date is updated',
                    ->{ checksum_owner.dates.last.update_attribute(:date, Time.now + 10.days) }

    it_behaves_like 'it works with both checksums modes',
                    'changes when a date is added',
                    ->{ create(:time_table_date, time_table: checksum_owner, date: 1.year.ago) }

    it_behaves_like 'it works with both checksums modes',
                    'changes when a period is updated',
                    ->{ checksum_owner.periods.last.update_attribute(:period_start, Time.now) }

    it_behaves_like 'it works with both checksums modes',
                    'changes when a period is added',
                    ->{ create(:time_table_period, period_start: 5.month.from_now, period_end: 6.month.from_now, time_table: checksum_owner) }
  end

  describe "#optimize_overlapping_periods" do
      before do
        subject.periods.clear
        subject.periods << Chouette::TimeTablePeriod.new(
                              :period_start => Date.new(2014, 6, 30),
                              :period_end => Date.new(2014, 7, 6))
        subject.periods << Chouette::TimeTablePeriod.new(
                              :period_start => Date.new(2014, 7, 6),
                              :period_end => Date.new(2014, 7, 14))
        subject.periods << Chouette::TimeTablePeriod.new(
                              :period_start => Date.new(2014, 6, 1),
                              :period_end => Date.new(2014, 6, 14))
        subject.periods << Chouette::TimeTablePeriod.new(
                              :period_start => Date.new(2014, 6, 3),
                              :period_end => Date.new(2014, 6, 4))
        subject.int_day_types = 4|8|16
      end
      it "should return 2 ordered periods" do
        periods = subject.optimize_overlapping_periods
        expect(periods.size).to eq(2)
        expect(periods[0].period_start).to eq(Date.new(2014, 6, 1))
        expect(periods[0].period_end).to eq(Date.new(2014, 6, 14))
        expect(periods[1].period_start).to eq(Date.new(2014, 6, 30))
        expect(periods[1].period_end).to eq(Date.new(2014, 7, 14))
      end
  end

  describe "#duplicate" do
    it "should be a copy of" do
      target=subject.duplicate
      expect(target.id).to be_nil
      expect(target.comment).to eq(I18n.t("activerecord.copy", name: subject.comment))
      expect(target.int_day_types).to eq(subject.int_day_types)
      expect(target.dates.size).to eq(subject.dates.size)
      target.dates.each do |d|
        expect(d.time_table_id).to be_nil
      end
      expect(target.periods.size).to eq(subject.periods.size)
      target.periods.each do |p|
        expect(p.time_table_id).to be_nil
      end
    end

    it "should accept a custom comment" do
      target=subject.duplicate(comment: "custom comment")
      expect(target.comment).to eq("custom comment")
    end
  end

  describe "#intersect_periods!" do
    let(:time_table) { Chouette::TimeTable.new int_day_types: Chouette::TimeTable::EVERYDAY }
    let(:periods) do
      [
        Date.new(2018, 1, 1)..Date.new(2018, 2, 1),
      ]
    end

    it "remove a date not included in given periods" do
      time_table.dates.build date: Date.new(2017,12,31)
      time_table.intersect_periods! periods
      expect(time_table.dates).to be_empty
    end

    it "keep a date included in given periods" do
      time_table.dates.build date: Date.new(2018,1,15)
      expect{time_table.intersect_periods! periods}.to_not change(time_table, :dates)
    end

    it "remove a period not included in given periods" do
      time_table.periods.build period_start: Date.new(2017,12,1), period_end: Date.new(2017,12,31)
      time_table.intersect_periods! periods
      expect(time_table.periods).to be_empty
    end

    it "modify a start period if not included in given periods" do
      period = time_table.periods.build period_start: Date.new(2017,12,1), period_end: Date.new(2018,1,15)
      time_table.intersect_periods! periods
      expect(period.period_start).to eq(Date.new(2018, 1, 1))
    end

    it "modify a end period if not included in given periods" do
      period = time_table.periods.build period_start: Date.new(2018,1,15), period_end: Date.new(2018,3,1)
      time_table.intersect_periods! periods
      expect(period.period_end).to eq(Date.new(2018, 2, 1))
    end

    it "keep a period included in given periods" do
      time_table.periods.build period_start: Date.new(2018,1,10), period_end: Date.new(2018,1,20)
      expect{time_table.intersect_periods! periods}.to_not change(time_table, :periods)
    end

    it "transforms single-day periods into dates" do
      time_table.periods.build period_start: Date.new(2018,2,1), period_end: Date.new(2018,3,1)
      time_table.intersect_periods! periods
      expect(time_table.periods).to be_empty
      expect(time_table.dates.size).to eq 1
      expect(time_table.dates.last.date).to eq Date.new(2018,2,1)
      expect(time_table.dates.last.in_out).to be_truthy
    end

    it "doesn't duplicate dates" do
      time_table.periods.build period_start: Date.new(2018,2,1), period_end: Date.new(2018,3,1)
      time_table.dates.build date: Date.new(2018,2,1), in_out: true
      time_table.intersect_periods! periods
      expect(time_table.periods).to be_empty
      expect(time_table.dates.size).to eq 1
      expect(time_table.dates.last.date).to eq Date.new(2018,2,1)
      expect(time_table.dates.last.in_out).to be_truthy
    end

    it 'should deal with another timetable with 2 separate periods' do
      time_table.periods.build period_start: Date.parse("01/12/2019"), period_end: Date.parse("10/01/2020")
      periods = [
        Date.parse("30/09/2019")..Date.parse("30/12/2019"),
        Date.parse("01/01/2020")..Date.parse("10/01/2020")
      ]

      time_table.intersect_periods!(periods)
      expect(time_table.periods.map { |p| p.period_start..p.period_end }).to eq([Date.parse("01/12/2019")..Date.parse("30/12/2019"), Date.parse("01/01/2020")..Date.parse("10/01/2020")])
    end

    it 'should deal with another timetable with 2 continuous periods' do
      time_table.periods.build [ { period_start: Date.parse("01/12/2019"), period_end: Date.parse("10/01/2020") } ]
      periods = [ Date.parse("30/09/2019")..Date.parse("31/12/2019"),Date.parse("01/01/2020")..Date.parse("10/01/2020") ]

      time_table.intersect_periods!(periods)
      expect(time_table.periods.map{|p| p.period_start..p.period_end }).to eq([Date.parse("01/12/2019")..Date.parse("31/12/2019"), Date.parse("01/01/2020")..Date.parse("10/01/2020")])
    end
  end

  describe "#remove_periods!" do
    let(:time_table) { Chouette::TimeTable.new int_day_types: Chouette::TimeTable::EVERYDAY }
    let(:periods) do
      [
        Date.new(2018, 1, 1)..Date.new(2018, 2, 1),
      ]
    end

    it "remove a date included in given periods" do
      time_table.dates.build date: Date.new(2018,1,15)
      time_table.remove_periods! periods
      expect(time_table.dates).to be_empty
    end

    it "remove all dates included in given periods" do
      (5..25).each do |n|
        time_table.dates.build date: Date.new(2018,1,n)
      end
      time_table.remove_periods! periods
      expect(time_table.dates).to be_empty
    end

    it "keep a date not included in given periods" do
      time_table.dates.build date: Date.new(2017,12,31)
      expect{time_table.remove_periods! periods}.to_not change(time_table, :dates)
    end

    it "modify a end period if included in given periods" do
      period = time_table.periods.build period_start: Date.new(2017,12,1), period_end: Date.new(2018,1,15)
      time_table.remove_periods! periods
      expect(period.period_end).to eq(Date.new(2017, 12, 31))
    end

    it "modify a start period if included in given periods" do
      period = time_table.periods.build period_start: Date.new(2018,1,15), period_end: Date.new(2018,3,1)
      time_table.remove_periods! periods
      expect(period.period_start).to eq(Date.new(2018, 2, 2))
    end

    it "remove a period included in given periods" do
      time_table.periods.build period_start: Date.new(2018,1,10), period_end: Date.new(2018,1,20)
      time_table.remove_periods! periods
      expect(time_table.periods).to be_empty
    end

    it "remove all periods included in given periods" do
      (5..25).each do |n|
        time_table.periods.build period_start: Date.new(2018,1,n), period_end: Date.new(2018,1,n+3)
      end
      time_table.remove_periods! periods
      expect(time_table.periods).to be_empty
    end

    it "split a period including a given period" do
      time_table.periods.build period_start: Date.new(2017,12,1), period_end: Date.new(2018,3,1)
      time_table.remove_periods! periods

      expected_ranges = [
        Date.new(2017,12,1)..Date.new(2017,12,31),
        Date.new(2018,2,2)..Date.new(2018,3,1)
      ]
      expect(time_table.periods.map(&:range)).to eq(expected_ranges)
    end

    it "creates a included Date if a single day remains from a period" do
      time_table.periods.build period_start: Date.new(2018, 1, 1), period_end: Date.new(2018, 2, 2)
      time_table.remove_periods! periods

      expect(time_table.periods.empty?).to be_truthy
      expect(time_table.dates.size).to eq(1)

      created_date = time_table.dates.first
      expect(created_date.date).to eq(Date.new(2018, 2, 2))
      expect(created_date.in_out).to be_truthy
    end

    it "creates a two included Dates if two days remain from a period" do
      time_table.periods.build period_start: Date.new(2017, 12, 31), period_end: Date.new(2018, 2, 2)
      time_table.remove_periods! periods

      expect(time_table.periods).to be_empty
      expect(time_table.dates.size).to eq(2)

      expect(time_table.dates.map(&:date)).to eq([Date.new(2017, 12, 31), Date.new(2018, 2, 2)])
      expect(time_table.dates.map(&:in_out).uniq).to eq([true])
    end

    it "doesn't duplicate dates" do
      time_table.periods.build period_start: Date.new(2017, 12, 31), period_end: Date.new(2018, 2, 2)
      time_table.dates.build date: Date.new(2017, 12, 31), in_out: true
      time_table.remove_periods! periods

      expect(time_table.periods).to be_empty
      expect(time_table.dates.size).to eq(2)

      expect(time_table.dates.map(&:date)).to eq([Date.new(2017, 12, 31), Date.new(2018, 2, 2)])
      expect(time_table.dates.map(&:in_out).uniq).to eq([true])
    end

    it "doesn't create an included Date outside circulation dates" do
      time_table.int_day_types = 0
      time_table.periods.build period_start: Date.new(2017, 12, 31), period_end: Date.new(2018, 2, 2)
      time_table.remove_periods! periods

      expect(time_table.periods).to be_empty
      expect(time_table.dates).to be_empty
    end

  end

  describe "#days_of_week" do

    def for_all_days_combination
      all_days = Chouette::TimeTable.all_days.map(&:to_sym)

      (0..all_days.size).each do |size|
        all_days.combination(size).each do |combination|
          yield combination
        end
      end
    end

    it "returns a DaysOfWeek with the same day selection than the TimeTable" do
      for_all_days_combination do |combination|
        time_table = Chouette::TimeTable.new

        combination.each do |day|
          time_table.send "#{day}=", true
        end

        expect(time_table.days_of_week.days).to match_array(combination)
      end
    end

  end

  describe "#to_timetable" do

    let(:time_table) { Chouette::TimeTable.new int_day_types: Chouette::TimeTable::EVERYDAY }

    describe "returned Timetable" do

      let(:date) { Date.new 2030, 1, 1 }

      it "has an included_date for each Date 'in" do
        time_table.dates.build date: date, in_out: true
        expect(time_table.to_timetable.included_dates).to match_array([date])
      end

      it "has an excluded_date for each Date 'in" do
        time_table.dates.build date: date, in_out: false
        expect(time_table.to_timetable.excluded_dates).to match_array([date])
      end

      it "has a period for each Period" do
        period = time_table.periods.build period_start: Date.new(2030, 1, 1), period_end: Date.new(2030, 2, 1)
        expected_period = Cuckoo::Timetable::Period.from(period.range)
        expect(time_table.to_timetable.periods).to match_array([expected_period])
      end

    end

  end

  describe "#apply" do

    let(:time_table) { Chouette::TimeTable.new }

    let(:date) { Date.new(2030,1,1) }
    let(:dates) { [ Date.new(2030,1,1), Date.new(2030,2,1) ]}
    let(:date_range) { Range.new(Date.new(2030,1,1), Date.new(2030,2,1)) }

    it "creates a Date 'in' for each included date" do
      time_table.apply(Cuckoo::Timetable.new included_dates: [dates])
      expect(time_table.dates.map(&:date)).to eq([dates])
      expect(time_table.dates.map(&:in_out).uniq).to eq([true])
    end

    it "creates a Date 'out' for each excluded date" do
      time_table.apply(Cuckoo::Timetable.new excluded_dates: [dates])
      expect(time_table.dates.map(&:date)).to eq([dates])
      expect(time_table.dates.map(&:in_out).uniq).to eq([false])
    end

    it "creates a Period for each period" do
      expect do
        time_table.apply(Cuckoo::Timetable.new periods: Cuckoo::Timetable::Period.from(date_range))
      end.to change { time_table.periods.size }.to(1)
      expect(time_table.periods.first).to have_attributes(period_start: date_range.min, period_end: date_range.max)
    end

    it "removes unexpected Dates 'in'" do
      time_table.dates.build date: date, in_out: true
      expect do
        time_table.apply(Cuckoo::Timetable.new)
      end.to change { time_table.dates.reject(&:destroyed?).size }.to(0)
    end

    it "removes unexpected Dates 'out'" do
      time_table.dates.build date: date, in_out: false
      expect do
        time_table.apply(Cuckoo::Timetable.new)
      end.to change { time_table.dates.reject(&:destroyed?).size }.to(0)
    end

    it "removes unexpected Period" do
      time_table.periods.build period_start: date_range.min, period_end: date_range.max
      expect do
        time_table.apply(Cuckoo::Timetable.new)
      end.to change { time_table.periods.reject(&:destroyed?).size }.to(0)
    end

    it "uses an uniq DaysOfWeek" do
      timetable = Cuckoo::Timetable::Builder.create do
        period("1/06","15/06", 'L......')
        period("1/07","15/07", 'L......')
      end

      expect do
        time_table.apply(timetable)
      end.to change(time_table, :int_day_types).from(ApplicationDaysSupport::NONE).to(ApplicationDaysSupport::MONDAY)
    end

    it "raise an ArgumentError when several DaysOfWeeks are defined" do
      timetable = Cuckoo::Timetable::Builder.create do
        period("1/06","15/06", 'L......')
        period("1/07","15/07", '.....SD')
      end

      expect do
        time_table.apply(timetable)
      end.to raise_error(ArgumentError)
    end

  end

  describe '#period' do
    subject { time_table.period }
    let(:time_table) { Chouette::TimeTable.new int_day_types: ApplicationDaysSupport::EVERYDAY }

    context "when TimeTable covers '2030-01-01..2030-12-31'" do
      before { time_table.periods.build period_start: Date.parse('2030-01-01'), period_end: Date.parse('2030-12-31') }
      it { is_expected.to eq(Period.parse('2030-01-01..2030-12-31')) }
    end
  end
end
