RSpec.describe ServiceCount, type: :model do
  let(:journey_pattern) { create :journey_pattern }
  let(:line_referential) { create :line_referential }
  let(:workbench) { create :workbench, line_referential: line_referential }
  let!(:line) { create :line, line_referential: line_referential }
  let!(:line2) { create :line, line_referential: line_referential }
  let(:route) { journey_pattern.route }
  let(:service) { JourneyPatternOfferService.new(journey_pattern) }

  let(:metadatas_1) do
    create :referential_metadata, lines: line_referential.lines,
                                  periodes: [(period_start..period_end.prev_day)]
  end

  let(:metadatas_2) do
    create :referential_metadata, lines: line_referential.lines,
                                  periodes: [(period_start.next..period_end)]
  end

  let(:referential)  { create :workbench_referential, workbench: workbench,
                                                      metadatas: [metadatas_1, metadatas_2] }
  let(:period_start) { 1.month.ago.to_date }
  let(:period_end)   { 1.month.since.to_date }

  before do
    referential.switch
    journey_pattern.route.update line: line
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
