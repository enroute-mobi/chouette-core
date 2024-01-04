# frozen_string_literal: true

RSpec.describe ServiceCount, type: :model do
  describe '.compute_for_referential' do
    subject { ServiceCount.compute_for_referential(referential) }

    let(:context) do
      Chouette.create do
        referential do
          time_table :time_table_a,
                     int_day_types: Cuckoo::Timetable::DaysOfWeek::SATURDAY | Cuckoo::Timetable::DaysOfWeek::SUNDAY,
                     periods: [Period.parse('2030-01-07..2030-01-20')]

          time_table :time_table_b,
                     periods: [Period.parse('2030-01-14..2030-01-27')]

          route do
            journey_pattern :journey_pattern1 do
              vehicle_journey time_tables: [:time_table_a]
              vehicle_journey time_tables: [:time_table_a]
              vehicle_journey time_tables: %i[time_table_a time_table_b]
              vehicle_journey time_tables: [:time_table_b]
            end
          end

          route do
            journey_pattern :journey_pattern2 do
              vehicle_journey time_tables: [:time_table_a]
            end
          end
        end
      end
    end

    let(:referential) { context.referential }

    let(:journey_pattern) { context.journey_pattern(:journey_pattern1) }
    let(:route) { journey_pattern.route }
    let(:line) { route.line }

    let(:journey_pattern2) { context.journey_pattern(:journey_pattern2) }
    let(:route2) { journey_pattern2.route }
    let(:line2) { route2.line }

    before { referential.switch }

    it 'cleans previous stats' do
      old_date = Date.parse('2023-11-24')
      ServiceCount.create!(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: old_date)

      expect { subject }.to change { ServiceCount.where(date: old_date).count }.from(1).to(0)
    end

    # rubocop:disable Layout/LineLength
    it 'computes all service counts' do
      subject
      expect(ServiceCount.all).to match_array(
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

    context "when an empty timetable is present" do
      before { referential.time_tables.first.periods.delete_all }

      it 'computes all service counts' do
        expect { subject }.to change(referential.service_counts, :count).from(0)
      end
    end

    context 'with excluded dates' do
      # rubocop:disable Metrics/BlockLength
      let(:context) do
        Chouette.create do
          referential do
            time_table :time_table_a,
                       int_day_types: Cuckoo::Timetable::DaysOfWeek::SATURDAY | Cuckoo::Timetable::DaysOfWeek::SUNDAY,
                       periods: [Period.parse('2030-01-07..2030-01-20')],
                       dates: [
                         Chouette::TimeTableDate.new(date: Date.parse('2030-01-12'), in_out: false),
                         Chouette::TimeTableDate.new(date: Date.parse('2030-01-20'), in_out: false)
                       ]

            time_table :time_table_b,
                       periods: [Period.parse('2030-01-14..2030-01-27')],
                       dates: [
                         Chouette::TimeTableDate.new(date: Date.parse('2030-01-14'), in_out: false),
                         Chouette::TimeTableDate.new(date: Date.parse('2030-01-27'), in_out: false)
                       ]

            route do
              journey_pattern :journey_pattern1 do
                vehicle_journey time_tables: [:time_table_a]
                vehicle_journey time_tables: [:time_table_a]
                vehicle_journey time_tables: %i[time_table_a time_table_b]
                vehicle_journey time_tables: [:time_table_b]
              end
            end

            route do
              journey_pattern :journey_pattern2 do
                vehicle_journey time_tables: [:time_table_a]
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/BlockLength

      it 'computes all service counts' do
        subject
        expect(ServiceCount.all).to match_array(
          [
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-13'), count: 3),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-15'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-16'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-17'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-18'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-19'), count: 4),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-20'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-21'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-22'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-23'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-24'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-25'), count: 2),
            have_attributes(line_id: line.id, route_id: route.id, journey_pattern_id: journey_pattern.id, date: Date.parse('2030-01-26'), count: 2),
            have_attributes(line_id: line2.id, route_id: route2.id, journey_pattern_id: journey_pattern2.id, date: Date.parse('2030-01-13'), count: 1),
            have_attributes(line_id: line2.id, route_id: route2.id, journey_pattern_id: journey_pattern2.id, date: Date.parse('2030-01-19'), count: 1)
          ]
        )
      end
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
