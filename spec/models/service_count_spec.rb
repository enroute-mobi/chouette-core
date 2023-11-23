# frozen_string_literal: true

RSpec.describe ServiceCount, type: :model do
  let(:line_referential) { create(:line_referential) }
  let(:workbench) { create(:workbench, line_referential: line_referential) }
  let(:line) { create(:line, line_referential: line_referential) }
  let(:line2) { create(:line, line_referential: line_referential) }
  let(:route) { create(:route, line: line) }
  let(:route2) { create(:route, line: line2) }
  let(:journey_pattern) { create(:journey_pattern, route: route) }
  let(:journey_pattern2) { create(:journey_pattern, route: route2) }

  let(:period_start) { Date.parse('2030-01-07') }
  let(:period_end)   { Date.parse('2030-01-27') }
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
    let(:time_table_a) do
      build(
        :time_table,
        int_day_types: Cuckoo::Timetable::DaysOfWeek::SATURDAY | Cuckoo::Timetable::DaysOfWeek::SUNDAY
      ).tap do |t|
        t.periods.new(period_start: Date.parse('2030-01-07'), period_end: Date.parse('2030-01-20'))
        t.save!
      end
    end
    let(:time_table_b) do
      build(:time_table, int_day_types: Cuckoo::Timetable::DaysOfWeek::EVERYDAY).tap do |t|
        t.periods.new(period_start: Date.parse('2030-01-14'), period_end: Date.parse('2030-01-27'))
        t.save!
      end
    end
    let!(:vehicle_journey1) do
      create(:vehicle_journey, journey_pattern: journey_pattern, time_tables: [time_table_a])
    end
    let!(:vehicle_journey2) do
      create(:vehicle_journey, journey_pattern: journey_pattern, time_tables: [time_table_a])
    end
    let!(:vehicle_journey3) do
      create(:vehicle_journey, journey_pattern: journey_pattern, time_tables: [time_table_a, time_table_b])
    end
    let!(:vehicle_journey4) do
      create(:vehicle_journey, journey_pattern: journey_pattern, time_tables: [time_table_b])
    end
    let!(:vehicle_journey_other) do
      create(:vehicle_journey, journey_pattern: journey_pattern2, time_tables: [time_table_a])
    end

    it 'cleans previous stats' do
      old_date = Date.parse('2023-11-24')
      ServiceCount.create!(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: old_date)

      expect do
        ServiceCount.compute_for_referential(referential)
      end.to change { ServiceCount.where(date: old_date).count }.from(1).to(0)
    end

    # rubocop:disable Layout/LineLength
    it 'computes all service counts' do
      ServiceCount.compute_for_referential(referential)
      expect(ServiceCount.where(['count > ?', 0])).to match_array(
        [
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-12'), count: 3),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-13'), count: 3),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-14'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-15'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-16'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-17'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-18'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-19'), count: 4),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-20'), count: 4),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-21'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-22'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-23'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-24'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-25'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-26'), count: 2),
          have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-27'), count: 2),
          have_attributes(line_id: line2.id, route_id: route2.id, journey_pattern_id: journey_pattern2.id, date: Date.parse('2030-01-12'), count: 1),
          have_attributes(line_id: line2.id, route_id: route2.id, journey_pattern_id: journey_pattern2.id, date: Date.parse('2030-01-13'), count: 1),
          have_attributes(line_id: line2.id, route_id: route2.id, journey_pattern_id: journey_pattern2.id, date: Date.parse('2030-01-19'), count: 1),
          have_attributes(line_id: line2.id, route_id: route2.id, journey_pattern_id: journey_pattern2.id, date: Date.parse('2030-01-20'), count: 1)
        ]
      )
    end
    # rubocop:enable Layout/LineLength
  end

  describe 'scopes' do
    before do
      %w[2020-01-01 2020-06-01 2020-12-01 2021-01-01].each { |d| create :service_count, date: d.to_date }
    end

    describe '#between' do
      let(:filtered_jpcbd_list) { ServiceCount.between('2020-05-01'.to_date, '2020-12-01'.to_date) }

      it 'should return ServiceCount items between the selected dates' do
        expect(filtered_jpcbd_list.count).to eq 2
      end
    end

    describe '#before' do
      let(:filtered_jpcbd_list) { ServiceCount.after('2020-05-01'.to_date) }

      it 'should return ServiceCount items after the selected date' do
        expect(filtered_jpcbd_list.count).to eq 3
      end
    end

    describe '#after' do
      let(:filtered_jpcbd_list) { ServiceCount.before('2020-05-01'.to_date) }

      it 'should return ServiceCount items before the selected date' do
        expect(filtered_jpcbd_list.count).to eq 1
      end
    end
  end
end
