RSpec.describe ServiceCount, type: :model do
  let(:line_referential) { create(:line_referential) }
  let(:line) { create(:line, line_referential: line_referential) }
  let(:line2) { create(:line, line_referential: line_referential) }
  let(:route) { create(:route, line: line) }
  let(:journey_pattern) { create(:journey_pattern, route: route) }
  let(:workbench) { create(:workbench, line_referential: line_referential) }

  let(:period_start) { 1.month.ago.to_date }
  let(:period_end)   { 1.month.since.to_date }
  let(:metadatas1) do
    create(:referential_metadata, lines: line_referential.lines, periodes: [period_start..period_end.prev_day])
  end
  let(:metadatas2) do
    create(:referential_metadata, lines: line_referential.lines, periodes: [period_start.next..period_end])
  end
  let(:referential) { create(:workbench_referential, workbench: workbench, metadatas: [metadatas1, metadatas2]) }

  let(:lines) { [line, line2] }

  before do
    lines
    referential.switch
  end

  describe '#compute_for_referential' do
    it 'creates stat objects for a referential' do
      expected_count = referential.metadatas_period.count * referential.associated_lines.count

      expect {
        ServiceCount.compute_for_referential(referential)
      }.to change { ServiceCount.count }.by(expected_count)
    end

    it 'can take an option to select lines to compute' do
      ServiceCount.compute_for_referential(referential, line_ids: [line.id])

      expect(
        ServiceCount.where(line_id: line.id).exists?
      ).to be_truthy

      expect(
        ServiceCount.where(line_id: line2.id).exists?
      ).to be_falsy
    end

    context 'CHOUETTE-3215' do
      let(:period_start) { Date.parse('2030-01-07') }
      let(:period_end) { Date.parse('2030-01-27') }
      let(:time_table_a) do
        build(:time_table, int_day_types: Timetable::DaysOfWeek::SATURDAY | Timetable::DaysOfWeek::SUNDAY).tap do |t|
          t.periods.new(period_start: Date.parse('2030-01-07'), period_end: Date.parse('2030-01-20'))
          t.save!
        end
      end
      let(:time_table_b) do
        build(:time_table, int_day_types: Timetable::DaysOfWeek::EVERYDAY).tap do |t|
          t.periods.new(period_start: Date.parse('2030-01-14'), period_end: Date.parse('2030-01-27'))
          t.save!
        end
      end
      let(:journey_pattern_target) { create(:journey_pattern, route: route) }
      let!(:vehicle_journey1) { create(:vehicle_journey, journey_pattern: journey_pattern_target, time_tables: [time_table_a] )}
      let!(:vehicle_journey2) { create(:vehicle_journey, journey_pattern: journey_pattern_target, time_tables: [time_table_a] )}
      let!(:vehicle_journey3) { create(:vehicle_journey, journey_pattern: journey_pattern_target, time_tables: [time_table_a, time_table_b] )}
      let!(:vehicle_journey4) { create(:vehicle_journey, journey_pattern: journey_pattern_target, time_tables: [time_table_b] )}
      let!(:vehicle_journey_other) { create(:vehicle_journey, journey_pattern: create(:journey_pattern, route: create(:route, line: line2)), time_tables: [time_table_a]) }

      it 'should compute all service counts' do
        ServiceCount.compute_for_referential(referential)
        expect(ServiceCount.where(['count > ?', 0])).to match_array([
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-12'), count: 3),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-13'), count: 3),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-14'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-15'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-16'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-17'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-18'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-19'), count: 4),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-20'), count: 4),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-21'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-22'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-23'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-24'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-25'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-26'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-27'), count: 2),
          have_attributes(line_id: vehicle_journey_other.journey_pattern.route.line_id, route_id: vehicle_journey_other.journey_pattern.route_id, journey_pattern_id: vehicle_journey_other.journey_pattern_id, date: Date.parse('2030-01-12'), count: 1),
          have_attributes(line_id: vehicle_journey_other.journey_pattern.route.line_id, route_id: vehicle_journey_other.journey_pattern.route_id, journey_pattern_id: vehicle_journey_other.journey_pattern_id, date: Date.parse('2030-01-13'), count: 1),
          have_attributes(line_id: vehicle_journey_other.journey_pattern.route.line_id, route_id: vehicle_journey_other.journey_pattern.route_id, journey_pattern_id: vehicle_journey_other.journey_pattern_id, date: Date.parse('2030-01-19'), count: 1),
          have_attributes(line_id: vehicle_journey_other.journey_pattern.route.line_id, route_id: vehicle_journey_other.journey_pattern.route_id, journey_pattern_id: vehicle_journey_other.journey_pattern_id, date: Date.parse('2030-01-20'), count: 1),
        ])
      end

      it 'should compute service counts for specific line' do
        ServiceCount.compute_for_referential(referential, line_ids: [line.id])
        expect(ServiceCount.where(['count > ?', 0])).to match_array([
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-12'), count: 3),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-13'), count: 3),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-14'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-15'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-16'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-17'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-18'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-19'), count: 4),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-20'), count: 4),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-21'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-22'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-23'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-24'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-25'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-26'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern_target.id, date: Date.parse('2030-01-27'), count: 2),
        ])
      end
    end
  end

  describe '#clean_previous_stats' do
    it 'delete records associated to specific lines' do
      ServiceCount.compute_for_referential(referential, line_ids: [line.id])
      ServiceCount.compute_for_referential(referential, line_ids: [line2.id])
      ServiceCount.clean_previous_stats([line2.id])

      expect(
        ServiceCount.where(line_id: line2.id).exists?
      ).to be_falsy

      expect(
        ServiceCount.where(line_id: line.id).exists?
      ).to be_truthy
    end
  end

  describe '#populate_for_journey_pattern' do
    it 'should create nothing without a vehicle_journey' do
      expect { ServiceCount.populate_for_journey_pattern(journey_pattern) }.to_not(
        change { ServiceCount.count }
      )
    end

    context 'with a vehicle_journey' do
      let!(:vehicle_journey) { create :vehicle_journey, journey_pattern: journey_pattern, time_tables: time_tables }
      let(:time_tables) { [time_table] }
      let(:time_table) { create :time_table, periods_count: 0, dates_count: 0 }
      let(:circulation_day) { period_start + 10 }

      context 'with no hole' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day)
          time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
          ServiceCount.populate_for_journey_pattern(journey_pattern)
        end

        it 'should create instances' do
          period_start.upto(period_end).each do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).exists?
            ).to be_truthy
          end
        end
      end

      context 'with a hole' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day.prev_day)
          time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
          ServiceCount.populate_for_journey_pattern(journey_pattern)
        end

        it 'should create instances' do
          period_start.upto(circulation_day.prev_day).each do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).exists?
            ).to be_truthy
          end
          circulation_day.next.upto(period_end).each do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).exists?
            ).to be_truthy
          end
        end
      end
    end
  end

  describe '#fill_blanks_for_empty_line' do
    it "should fill with holes" do
      expect { ServiceCount.fill_blanks_for_empty_line(line, referential: referential) }.to(
        change { ServiceCount.count }.by(period_end - period_start + 1)
      )
      period_start.upto(period_end) do |date|
        expect(
          ServiceCount.where(line_id: line.id, date: date).last.count
        ).to be_zero
      end
    end
  end

  describe '#fill_blanks_for_empty_route' do
    it "should fill with holes" do
      expect { ServiceCount.fill_blanks_for_empty_route(route, referential: referential) }.to(
        change { ServiceCount.count }.by(period_end - period_start + 1)
      )
      period_start.upto(period_end) do |date|
        expect(
          ServiceCount.where(line_id: line.id, date: date).last.count
        ).to be_zero
      end
    end
  end

  describe '#fill_blanks_for_journey_pattern' do
    it "should fill with holes" do
      ServiceCount.populate_for_journey_pattern(journey_pattern)
      expect { ServiceCount.fill_blanks_for_journey_pattern(journey_pattern) }.to(
        change { ServiceCount.count }.by(period_end - period_start + 1)
      )
      period_start.upto(period_end) do |date|
        expect(
          ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).last.count
        ).to be_zero
      end
    end

    context 'with a vehicle_journey' do
      let!(:vehicle_journey) { create :vehicle_journey, journey_pattern: journey_pattern, time_tables: time_tables }
      let(:time_tables) { [time_table] }
      let(:time_table) { create :time_table, periods_count: 0, dates_count: 0 }
      let(:circulation_day) { period_start + 10 }

      context 'with no hole' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day)
          time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
          ServiceCount.populate_for_journey_pattern(journey_pattern)
        end

        it 'should do nothing' do
          expect { ServiceCount.fill_blanks_for_journey_pattern(journey_pattern) }.to_not(
            change { ServiceCount.count }
          )
        end
      end

      context 'with a hole' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day.prev_day)
          time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
          ServiceCount.populate_for_journey_pattern(journey_pattern)
        end

        it 'should create instances' do
          ServiceCount.fill_blanks_for_journey_pattern(journey_pattern)
          expect(
            ServiceCount.where(journey_pattern_id: journey_pattern.id, date: circulation_day).exists?
          ).to be_truthy

          expect(
            ServiceCount.where(journey_pattern_id: journey_pattern.id, date: circulation_day).last.count
          ).to be_zero
        end
      end

      context 'with a hole at the start' do
        before do
          time_table.periods.create!(period_start: circulation_day, period_end: period_end)
          ServiceCount.populate_for_journey_pattern(journey_pattern)
        end

        it 'should create instances' do
          expect { ServiceCount.fill_blanks_for_journey_pattern(journey_pattern) }.to(
            change { ServiceCount.count }.by(circulation_day - period_start)
          )
          period_start.upto(period_end) do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date)
            ).to be_exists
          end
          period_start.upto(circulation_day.prev_day) do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).last.count
            ).to be_zero
          end
          circulation_day.upto(period_end) do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).last.count
            ).to eq 1
          end
        end
      end

      context 'with a hole at the end' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day)
          ServiceCount.populate_for_journey_pattern(journey_pattern)
        end

        it 'should create instances' do
          expect { ServiceCount.fill_blanks_for_journey_pattern(journey_pattern) }.to(
            change { ServiceCount.count }.by(period_end - circulation_day)
          )
          period_start.upto(period_end) do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date)
            ).to be_exists
          end
          period_start.upto(circulation_day) do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).last.count
            ).to eq 1
          end
          circulation_day.next.upto(period_end) do |date|
            expect(
              ServiceCount.where(journey_pattern_id: journey_pattern.id, date: date).last.count
            ).to be_zero
          end
        end
      end
    end
  end

  describe 'scopes' do
    before do
      %w[2020-01-01 2020-06-01 2020-12-01 2021-01-01].each { |d| create :service_count, date: d.to_date }
    end

    describe '#between' do
      let(:filtered_jpcbd_list) { ServiceCount.between('2020-05-01'.to_date, '2020-12-01'.to_date) }

      it 'should return ServiceCount items between the selected dates' do
        expect( filtered_jpcbd_list.count ).to eq 2
      end
    end

    describe '#before' do
      let(:filtered_jpcbd_list) { ServiceCount.after('2020-05-01'.to_date) }

      it 'should return ServiceCount items after the selected date' do
        expect( filtered_jpcbd_list.count ).to eq 3
      end
    end

    describe '#after' do
      let(:filtered_jpcbd_list) { ServiceCount.before('2020-05-01'.to_date) }

      it 'should return ServiceCount items before the selected date' do
        expect( filtered_jpcbd_list.count ).to eq 1
      end
    end
  end
end
