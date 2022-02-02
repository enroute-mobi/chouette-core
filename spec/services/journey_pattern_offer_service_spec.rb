RSpec.describe JourneyPatternOfferService do
  let(:journey_pattern) { create :journey_pattern }
  let(:line) { create :line }
  let(:service) { JourneyPatternOfferService.new(journey_pattern) }
  let(:referential_metadatas_1) do
    create :referential_metadata, line_ids: [line.id], periodes: [(period_start..period_end.prev_day)]
  end
  let(:referential_metadatas_2) do
    create :referential_metadata, line_ids: [line.id], periodes: [(period_start.next..period_end)]
  end
  let(:referential)  { create :workbench_referential, metadatas: [referential_metadatas_1, referential_metadatas_2] }
  let(:period_start) { 1.month.ago.to_date }
  let(:period_end)   { 1.month.since.to_date }

  before(:each) do
    referential.switch
    journey_pattern.route.update line: line
  end

  it 'should detect the timespan' do
    expect(service.period_start).to eq period_start
    expect(service.period_end).to eq period_end
  end

  context 'with a vehicle_journey' do
    let!(:vehicle_journey) { create :vehicle_journey, journey_pattern: journey_pattern, time_tables: time_tables }
    let(:time_tables) { [time_table] }
    let(:time_table) { create :time_table, periods_count: 0, dates_count: 0, int_day_types: ApplicationDaysSupport::EVERYDAY }
    let(:circulation_day) { period_start + 10 }

    context 'with a single day of circulation' do
      before do
        time_table.dates.create(date: circulation_day, in_out: true)
      end

      it 'should detect the circulation days' do
        expect(service.circulation_dates).to eq(
          circulation_day => 1
        )
      end
    end

    context 'with a single day period of circulation' do
      let(:circulation_day) { (period_start + 15.days).beginning_of_week }

      context 'matching application days' do
        before do
          time_table.update int_day_types: ApplicationDaysSupport::MONDAY
          time_table.periods.create!(period_start: circulation_day.prev_day, period_end: circulation_day)
        end

        it 'should detect the circulation days' do
          expect(service.circulation_dates).to eq(
            circulation_day => 1
          )
        end

        context 'and excluded' do
          before do
            time_table.dates.create!(date: circulation_day, in_out: false)
          end

          it 'should detect the circulation days' do
            expect(service.circulation_dates).to be_empty
          end
        end
      end

      context 'with no hole' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day)
          time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
        end

        it 'should detect the circulation days' do
          period_start.upto(period_end).each do |date|
            expect(service.circulation_dates[date]).to eq 1
          end
        end
      end

      context 'with a small hole' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day.prev_day)
          time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
        end

        it 'should detect the circulation days' do
          period_start.upto(circulation_day.prev_day).each do |date|
            expect(service.circulation_dates[date]).to eq 1
          end
          circulation_day.next.upto(period_end).each do |date|
            expect(service.circulation_dates[date]).to eq 1
          end
        end
      end

      context 'with a large hole' do
        before do
          time_table.periods.create!(period_start: period_start, period_end: circulation_day - 2)
          time_table.periods.create!(period_start: circulation_day + 2, period_end: period_end)
        end

        it 'should detect the circulation days' do
          period_start.upto(circulation_day - 2).each do |date|
            expect(service.circulation_dates[date]).to eq 1
          end
          (circulation_day + 3).upto(period_end).each do |date|
            expect(service.circulation_dates[date]).to eq 1
          end
        end
      end

      context 'not matching days' do
        before do
          time_table.update int_day_types: ApplicationDaysSupport::ALL_DAYS
          time_table.periods.create!(period_start: circulation_day + 365, period_end: circulation_day + 400)
        end

        it 'should detect the circulation days' do
          expect(service.circulation_dates).to eq({})
        end
      end

      context 'not matching application days' do
        before do
          time_table.update int_day_types: ApplicationDaysSupport::TUESDAY
          time_table.periods.create!(period_start: circulation_day.prev_day, period_end: circulation_day)
        end

        it 'should detect the circulation days' do
          expect(service.circulation_dates).to eq({})
        end
      end

      context 'with 2 timetables' do
        let(:time_table_2) { create :time_table, periods_count: 0, dates_count: 0 }
        let(:time_tables) { [time_table, time_table_2] }

        context 'with no hole' do
          before do
            time_table.periods.create!(period_start: period_start, period_end: circulation_day)
            time_table_2.periods.create!(period_start: circulation_day.next, period_end: period_end)
          end

          it 'should detect the circulation days' do
            period_start.upto(period_end).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
          end
        end

        context 'with a small hole' do
          before do
            time_table.periods.create!(period_start: period_start, period_end: circulation_day.prev_day)
            time_table_2.periods.create!(period_start: circulation_day.next, period_end: period_end)
          end

          it 'should detect the circulation days' do
            period_start.upto(circulation_day.prev_day).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
            circulation_day.next.upto(period_end).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
          end
        end

        context 'with a large hole' do
          before do
            time_table.periods.create!(period_start: period_start, period_end: circulation_day - 2)
            time_table_2.periods.create!(period_start: circulation_day + 2, period_end: period_end)
          end

          it 'should detect the circulation days' do
            period_start.upto(circulation_day - 2).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
            (circulation_day + 3).upto(period_end).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
          end
        end
      end
    end

    context 'with a second vehicle_journey' do
      let!(:vehicle_journey_2) { create :vehicle_journey, journey_pattern: journey_pattern, time_tables: time_tables_2 }
      context 'with the same time_table' do
        let(:time_tables_2) { time_tables }

        context 'with a single day period of circulation' do
          let(:circulation_day) { (period_start + 15.days).beginning_of_week }

          context 'matching application days' do
            before do
              time_table.update int_day_types: ApplicationDaysSupport::MONDAY
              time_table.periods.create!(period_start: circulation_day.prev_day, period_end: circulation_day)
            end

            it 'should detect the circulation days' do
              expect(service.circulation_dates).to eq(
                circulation_day => 2
              )
            end
          end

          context 'with no hole' do
            before do
              time_table.periods.create!(period_start: period_start, period_end: circulation_day)
              time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
            end

            it 'should detect the circulation days' do
              period_start.upto(period_end).each do |date|
                expect(service.circulation_dates[date]).to eq 2
              end
            end
          end

          context 'with a small hole' do
            before do
              time_table.periods.create!(period_start: period_start, period_end: circulation_day.prev_day)
              time_table.periods.create!(period_start: circulation_day.next, period_end: period_end)
            end

            it 'should detect the circulation days' do
              period_start.upto(circulation_day.prev_day).each do |date|
                expect(service.circulation_dates[date]).to eq 2
              end
              circulation_day.next.upto(period_end).each do |date|
                expect(service.circulation_dates[date]).to eq 2
              end
            end
          end

          context 'with a large hole' do
            before do
              time_table.periods.create!(period_start: period_start, period_end: circulation_day - 2)
              time_table.periods.create!(period_start: circulation_day + 2, period_end: period_end)
            end

            it 'should detect the circulation days' do
              period_start.upto(circulation_day - 2).each do |date|
                expect(service.circulation_dates[date]).to eq 2
              end
              (circulation_day + 3).upto(period_end).each do |date|
                expect(service.circulation_dates[date]).to eq 2
              end
            end
          end

          context 'not matching days' do
            before do
              time_table.update int_day_types: ApplicationDaysSupport::ALL_DAYS
              time_table.periods.create!(period_start: circulation_day + 365, period_end: circulation_day + 400)
            end

            it 'should detect the circulation days' do
              expect(service.circulation_dates).to eq({})
            end
          end

          context 'not matching application days' do
            before do
              time_table.update int_day_types: ApplicationDaysSupport::TUESDAY
              time_table.periods.create!(period_start: circulation_day.prev_day, period_end: circulation_day)
            end

            it 'should detect the circulation days' do
              expect(service.circulation_dates).to eq({})
            end
          end
        end
      end

      context 'with a distinct time_table' do
        let(:time_tables_2) { [time_table_2] }
        let(:time_table_2) { create :time_table, periods_count: 0, dates_count: 0 }

        context 'with no hole' do
          before do
            time_table.periods.create!(period_start: period_start, period_end: circulation_day)
            time_table_2.periods.create!(period_start: circulation_day.next, period_end: period_end)
          end

          it 'should detect the circulation days' do
            period_start.upto(period_end).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
          end
        end

        context 'with a small hole' do
          before do
            time_table.periods.create!(period_start: period_start, period_end: circulation_day.prev_day)
            time_table_2.periods.create!(period_start: circulation_day.next, period_end: period_end)
          end

          it 'should detect the circulation days' do
            period_start.upto(circulation_day.prev_day).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
            circulation_day.next.upto(period_end).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
          end
        end

        context 'with a large hole' do
          before do
            time_table.periods.create!(period_start: period_start, period_end: circulation_day - 4)
            time_table_2.periods.create!(period_start: circulation_day, period_end: period_end)
          end

          it 'should detect the circulation days' do
            period_start.upto(circulation_day - 4).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
            circulation_day.next.upto(period_end).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
          end
        end

        context 'with an overlap' do
          before do
            time_table.periods.create!(period_start: period_start, period_end: circulation_day.next)
            time_table_2.periods.create!(period_start: circulation_day.prev_day, period_end: period_end)
          end

          it 'should detect the circulation days' do
            period_start.upto(circulation_day - 2).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
            (circulation_day + 2).upto(period_end).each do |date|
              expect(service.circulation_dates[date]).to eq 1
            end
            circulation_day.prev_day.upto(circulation_day.next).each do |date|
              expect(service.circulation_dates[date]).to eq 2
            end
          end
        end
      end
    end
  end
end
