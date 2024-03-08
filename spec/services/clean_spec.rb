RSpec.describe Clean::Metadata::InPeriod do
  let(:context) do
    Chouette.create do
      3.times { line }
      referential
    end
  end
  let(:referential) { context.referential }
  let(:lines) { context.lines }

  before { referential.metadatas.clear }

  def period(from, to)
    Range.new Date.parse(from), Date.parse(to)
  end

  describe "#clean_metadata" do
    context "when the clean range is 2030-06-10..2030-06-20" do
      let(:clean) { Clean::Metadata::InPeriod.new scope, period('2030-06-10', '2030-06-20') }

      context "when the scope is the whole Referential (no restriction)" do
        let(:scope) { Clean::Scope::Referential.new referential }
        let(:metadata) { referential.metadatas.build line_ids: lines.map(&:id), periodes: [ metadata_period ] }

        context "when the metadata covers 2030-06-11..2030-06-19" do
          let(:metadata_period) { period('2030-06-11', '2030-06-19') }

          it "should be destroyed" do
            expect { clean.clean_metadata(metadata) }.to change(metadata, :destroyed?).to(true)
          end
        end

        context "when the metadata covers 2030-06-10..2030-06-20" do
          let(:metadata_period) { period('2030-06-10', '2030-06-20') }

          it "should be removed" do
            expect { clean.clean_metadata(metadata) }.to change(metadata, :destroyed?).to(true)
          end
        end

        context "when the metadata covers 2030-06-01..2030-06-15" do
          let(:metadata_period) { period('2030-06-01', '2030-06-15') }

          it "should be updated to cover 2030-06-01..2030-06-09" do
            expect { clean.clean_metadata(metadata) }.
              to change(metadata, :periodes).to([period('2030-06-01', '2030-06-09')])
          end
        end

        context "when the metadata covers 2030-06-15..2030-06-30" do
          let(:metadata_period) { period('2030-06-15', '2030-06-30') }

          it "should be updated to cover 2030-06-21..2030-06-30" do
            expect { clean.clean_metadata(metadata) }.
              to change(metadata, :periodes).to([period('2030-06-21', '2030-06-30')])
          end
        end

        context "when the metadata covers 2030-06-01..2030-06-30" do
          let(:metadata_period) { period('2030-06-01', '2030-06-30') }

          it "should be updated to cover 2030-06-01..2030-06-19 and 2030-06-21..2030-06-30" do
            expect { clean.clean_metadata(metadata) }.
              to change(metadata, :periodes).to([period('2030-06-01', '2030-06-19'), period('2030-06-21', '2030-06-30')])
          end
        end

        context "when the metadata covers 2030-05-01..2030-05-31" do
          let(:metadata_period) { period('2030-05-01', '2030-05-31') }

          it "should be unchanged" do
            expect { clean.clean_metadata(metadata) }.to_not change(metadata, :periodes)
          end
        end
      end

      context "when the scope is restricted to a single Line" do
        let(:line) { lines.first }
        let(:other_line_ids) { lines.map(&:id) - [line.id]}

        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), line }
        let(:metadata) { referential.metadatas.build line_ids: lines.map(&:id), periodes: [ metadata_period ] }

        context "when the metadata covers 2030-06-11..2030-06-19" do
          let(:metadata_period) { period('2030-06-11', '2030-06-19') }

          it "deletes all metadatas on the scoped line" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to_not include(an_object_having_attributes(line_id: line.id))
          end

          it "keeps metadatas on other lines" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to include(*other_line_ids.map { |id| an_object_having_attributes(line_id: id, period: metadata_period) })
          end
        end

        context "when the metadata covers 2030-06-10..2030-06-20" do
          let(:metadata_period) { period('2030-06-10', '2030-06-20') }

          it "deletes all metadatas on the scoped line" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to_not include(an_object_having_attributes(line_id: line.id))
          end

          it "keeps metadatas on other lines" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to include(*other_line_ids.map { |id| an_object_having_attributes(line_id: id, period: metadata_period) })
          end
        end

        context "when the metadata covers 2030-06-01..2030-06-15" do
          let(:metadata_period) { period('2030-06-01', '2030-06-15') }

          it "should cover 2030-06-01..2030-06-09 for the scoped line" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to include(an_object_having_attributes(line_id: line.id, period: period('2030-06-01','2030-06-15')))
          end

          it "keeps unchanged metadatas on other lines" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to include(*other_line_ids.map { |id| an_object_having_attributes(line_id: id, period: metadata_period) })
          end
        end

        context "when the metadata covers 2030-06-15..2030-06-30" do
          let(:metadata_period) { period('2030-06-15', '2030-06-30') }

          it "should cover 2030-06-21..2030-06-30 for the scoped line" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to include(an_object_having_attributes(line_id: line.id, period: period('2030-06-21','2030-06-30')))
          end

          it "keeps unchanged metadatas on other lines" do
            clean.clean_metadata(metadata)
            expect(referential.line_periods).to include(*other_line_ids.map { |id| an_object_having_attributes(line_id: id, period: metadata_period) })
          end
        end

      end
    end
  end

  describe "#metadatas" do
    subject { clean.metadatas }

    context "when the clean range is 2030-06-10..2030-06-20" do
      let(:clean) { Clean::Metadata::InPeriod.new scope, period('2030-06-10', '2030-06-20') }

      context "when the scope is the whole Referential (no restriction)" do
        let(:scope) { Clean::Scope::Referential.new referential }
        let(:metadata) { referential.metadatas.create! line_ids: lines.map(&:id), periodes: [ metadata_period ] }

        context "when a metadata covers 2030-06-11..2030-06-19" do
          let(:metadata_period) { period('2030-06-11', '2030-06-19') }
          it { is_expected.to include(metadata) }
        end

        context "when the metadata covers 2030-06-10..2030-06-20" do
          let(:metadata_period) { period('2030-06-10', '2030-06-20') }
          it { is_expected.to include(metadata) }
        end

        context "when the metadata covers 2030-06-01..2030-06-15" do
          let(:metadata_period) { period('2030-06-01', '2030-06-15') }
          it { is_expected.to include(metadata) }
        end

        context "when the metadata covers 2030-06-15..2030-06-30" do
          let(:metadata_period) { period('2030-06-15', '2030-06-30') }
          it { is_expected.to include(metadata) }
        end

        context "when the metadata covers 2030-06-01..2030-06-30" do
          let(:metadata_period) { period('2030-06-01', '2030-06-30') }
          it { is_expected.to include(metadata) }
        end

        context "when the metadata covers 2030-05-01..2030-05-31" do
          let(:metadata_period) { period('2030-05-01', '2030-05-31') }
          it { is_expected.to_not include(metadata) }
        end
      end

      context "when the scope is restricted to a single Line" do
        let(:line) { lines.first }

        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), line }

        context "when the metadata is associated to the scoped line" do
          let(:metadata) { referential.metadatas.create! line_ids: lines.map(&:id), periodes: [ metadata_period ] }

          context "when the metadata covers 2030-06-01..2030-06-30" do
            let(:metadata_period) { period('2030-06-01', '2030-06-30') }
            it { is_expected.to include(metadata) }
          end

          context "when the metadata covers 2030-05-01..2030-05-31" do
            let(:metadata_period) { period('2030-05-01', '2030-05-31') }
            it { is_expected.to_not include(metadata) }
          end
        end

        context "when the metadata isn't associated to the scoped line" do
          let(:metadata) { referential.metadatas.create! line_ids: lines.map(&:id) - [line.id], periodes: [ metadata_period ] }

          context "when the metadata covers 2030-06-01..2030-06-30" do
            let(:metadata_period) { period('2030-06-01', '2030-06-30') }
            it { is_expected.to_not include(metadata) }
          end

          context "when the metadata covers 2030-05-01..2030-05-31" do
            let(:metadata_period) { period('2030-05-01', '2030-05-31') }
            it { is_expected.to_not include(metadata) }
          end
        end
      end
    end
  end

  describe "#clean!" do
    context "when the clean range is 2030-06-10..2030-06-20" do
      let(:clean) { Clean::Metadata::InPeriod.new scope, period('2030-06-10', '2030-06-20') }

      context "when the scope is the whole Referential (no restriction)" do
        let(:scope) { Clean::Scope::Referential.new(referential) }

        context "when a metadata covers 2030-06-01..2030-06-12, 2030-06-14..2030-06-16 and 2030-06-18..2030-06-30" do
          before do
            periods = [ period('2030-06-01', '2030-06-12'), period('2030-06-14', '2030-06-16'), period('2030-06-18', '2030-06-30') ]
            referential.metadatas.create! line_ids: lines.map(&:id), periodes: periods
          end

          it "should update the periods to 2030-06-01..2030-06-09 and 2030-06-21..2030-06-30" do
            clean.clean!
            referential.metadatas.reload

            periods = [ period('2030-06-01','2030-06-09'), period('2030-06-21','2030-06-30') ]
            expect(referential.metadatas).to contain_exactly(an_object_having_attributes(periodes: periods))
          end

        end
      end

      context "when the scope is restricted to a single Line" do
        let(:line) { lines.first }
        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), line }

        let(:other_line_ids) { lines.map(&:id) - [line.id]}

        context "when a metadata covers all lines on 2030-06-01..2030-06-12, 2030-06-14..2030-06-16 and 2030-06-18..2030-06-30" do
          before do
            periods = [ period('2030-06-01', '2030-06-12'), period('2030-06-14', '2030-06-16'), period('2030-06-18', '2030-06-30') ]
            referential.metadatas.create! line_ids: lines.map(&:id), periodes: periods
          end

          it "should two metadatas, one on the scoped line, one for the other lines" do
            clean.clean!
            referential.metadatas.reload

            expect(referential.metadatas).to contain_exactly(an_object_having_attributes(line_ids: [line.id]),
                                                             an_object_having_attributes(line_ids: other_line_ids))
          end

          it "should leave a metdata on the scope line on 2030-06-01..2030-06-09 and 2030-06-21..2030-06-30" do
            clean.clean!
            referential.metadatas.reload

            periods = [ period('2030-06-01','2030-06-09'), period('2030-06-21','2030-06-30') ]
            expect(referential.metadatas).to include(an_object_having_attributes(line_ids: [line.id], periodes: periods))
          end

          it "should leave unchanged periods for other lines" do
            clean.clean!
            referential.metadatas.reload

            periods = [ period('2030-06-01', '2030-06-12'), period('2030-06-14', '2030-06-16'), period('2030-06-18', '2030-06-30') ]
            expect(referential.metadatas).to include(an_object_having_attributes(line_ids: other_line_ids, periodes: periods))
          end

        end
      end

    end
  end

end

RSpec.describe Clean::Metadata::Before do
  let(:context) do
    Chouette.create do
      3.times { line }
      referential
    end
  end
  let(:referential) { context.referential }
  let(:lines) { context.lines }

  before { referential.metadatas.clear }

  def period(from, to)
    Range.new Date.parse(from), Date.parse(to)
  end

  describe "#clean!" do
    context "when the clean date is 2030-06-10" do
      let(:clean) { Clean::Metadata::Before.new scope, Date.parse('2030-06-10') }

      context "when the scope is the whole Referential (no restriction)" do
        let(:scope) { Clean::Scope::Referential.new(referential) }

        context "when a metadata covers 2030-06-01..2030-06-15, 2030-06-16..2030-06-30" do
          before do
            periods = [ period('2030-06-01', '2030-06-15'), period('2030-06-16', '2030-06-20') ]
            referential.metadatas.create! line_ids: lines.map(&:id), periodes: periods
          end

          it "should update the periods to 2030-06-11..2030-06-15 and 2030-06-16..2030-06-30" do
            clean.clean!
            referential.metadatas.reload

            periods = [ period('2030-06-11','2030-06-15'), period('2030-06-16','2030-06-30') ]
            expect(referential.metadatas).to contain_exactly(an_object_having_attributes(periodes: periods))
          end

        end
      end

      context "when the scope is restricted to a single Line" do
        let(:line) { lines.first }
        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), line }

        let(:other_line_ids) { lines.map(&:id) - [line.id]}

        context "when a metadata covers 2030-06-01..2030-06-15, 2030-06-16..2030-06-30" do
          before do
            periods = [ period('2030-06-01', '2030-06-15'), period('2030-06-16', '2030-06-30') ]
            referential.metadatas.create! line_ids: lines.map(&:id), periodes: periods
          end

          it "should two metadatas, one on the scoped line, one for the other lines" do
            clean.clean!
            referential.metadatas.reload

            expect(referential.metadatas).to contain_exactly(an_object_having_attributes(line_ids: [line.id]),
                                                             an_object_having_attributes(line_ids: other_line_ids))
          end

          it "should leave a metadata on the scope line on 2030-06-11..2030-06-15 and 2030-06-16..2030-06-30" do
            clean.clean!
            referential.metadatas.reload

            periods = [ period('2030-06-11','2030-06-15'), period('2030-06-16','2030-06-30') ]
            expect(referential.metadatas).to include(an_object_having_attributes(line_ids: [line.id], periodes: periods))
          end

          it "should leave unchanged periods for other lines" do
            clean.clean!
            referential.metadatas.reload

            periods = [ period('2030-06-01', '2030-06-15'), period('2030-06-16', '2030-06-30') ]
            expect(referential.metadatas).to include(an_object_having_attributes(line_ids: other_line_ids, periodes: periods))
          end

        end
      end

    end
  end
end

RSpec.describe Clean::Timetable::Date::InPeriod do
  let(:context) do
    Chouette.create do
      referential do
        time_table
      end
    end
  end
  let(:referential) { context.referential }
  before { referential.switch }

  let(:timetable) { context.time_table }

  let(:timetable_date) do
    timetable.dates.create!(date: date, in_out: date_included)
  end

  let(:date_included) { true }

  def period(from, to)
    Range.new Date.parse(from), Date.parse(to)
  end

  context "#dates" do
    subject { clean.dates }

    context "when the clean range is 2030-06-10..2030-06-20" do
      let(:clean) { Clean::Timetable::Date::InPeriod.new scope, period('2030-06-10', '2030-06-20') }

      context "when the scope is the whole Referential (no restriction)" do
        let(:scope) { Clean::Scope::Referential.new referential }

        context "when a timetable date is 2030-06-10" do
          let(:date) { Date.parse("2030-06-10") }
          it { is_expected.to include(timetable_date) }
        end

        context "when a timetable date is 2030-06-20" do
          let(:date) { Date.parse("2030-06-20") }
          it { is_expected.to include(timetable_date) }
        end

        context "when a timetable date is 2030-06-09" do
          let(:date) { Date.parse("2030-06-09") }
          it { is_expected.to_not include(timetable_date) }
        end

        context "when a timetable date is 2030-06-21" do
          let(:date) { Date.parse("2030-06-21") }
          it { is_expected.to_not include(timetable_date) }
        end
      end

      context "when the scope is the whole Referential (no restriction)" do

        let(:context) do
          Chouette.create do
            line :scoped_line
            line :other_line

            referential lines: [ :scoped_line, :other_line ] do
              time_table
              route(line: :scoped_line) { vehicle_journey :scoped }
              route(line: :other_line) { vehicle_journey :other }
            end
          end
        end

        let(:line) { context.line(:scoped_line) }
        let(:other_line) { context.line(:other_line) }

        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), line }

        context "when a timetable date is associated to the scoped line" do
          before { context.vehicle_journey(:scoped).time_tables << timetable }

          context "on 2030-06-15" do
            let(:date) { Date.parse("2030-06-15") }
            it { is_expected.to include(timetable_date) }
          end

          context "on 2030-05-15" do
            let(:date) { Date.parse("2030-05-15") }
            it { is_expected.to_not include(timetable_date) }
          end
        end

        context "when a timetable date isn't associated to the scoped line" do
          before { context.vehicle_journey(:other).time_tables << timetable }

          context "on 2030-06-15" do
            let(:date) { Date.parse("2030-06-15") }
            it { is_expected.to_not include(timetable_date) }
          end

          context "on 2030-05-15" do
            let(:date) { Date.parse("2030-05-15") }
            it { is_expected.to_not include(timetable_date) }
          end
        end
      end
    end
  end

end

RSpec.describe Clean::Timetable::Date::ExcludedWithoutPeriod do
  let(:context) do
    Chouette.create do
      referential do
        time_table periods: [], dates_excluded: [Date.current]
      end
    end
  end
  let(:referential) { context.referential }
  before { referential.switch }

  let(:time_table) { context.time_table }
  let(:date) { time_table.dates.excluded.first }

  let(:scope) { Clean::Scope::Referential.new referential }
  subject(:clean) { described_class.new scope }

  describe '#dates' do
    subject { clean.dates }

    context 'when the TimeTable has a Period' do
      before { time_table.periods.create! range: Period.from(:today).during(10.days) }

      it { is_expected.to_not include(date) }
    end

    context 'when the TimeTable has no Period' do
      before { time_table.periods.delete_all }

      it { is_expected.to include(date) }
    end
  end
end

RSpec.describe Clean::InPeriod do
  let(:context) do
    Chouette.create do
      line :scoped
      line :other
      referential lines: [ :scoped ], periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ] do
        time_table periods: [ Date.parse("2030-06-01")..Date.parse("2030-06-30") ]
        vehicle_journey
      end
    end
  end
  let(:referential) { context.referential }
  before { referential.switch }

  let(:vehicle_journey) { context.vehicle_journey }
  let(:timetable) { context.time_table }
  let(:line) { context.line :scoped }

  before { vehicle_journey.time_tables << timetable }

  def period(from, to)
    Range.new Date.parse(from), Date.parse(to)
  end

  describe '#clean!' do
    context "with a Referential containing a single Vehicle Journey and a Timetable over 2030-06-01..2030-06-30" do
      context "when the scope is the whole Referential (no restriction)" do
        let(:scope) { Clean::Scope::Referential.new referential }

        context "when the clean range is 2030-06-10..2030-06-20" do
          let(:clean) { Clean::InPeriod.new scope, period('2030-06-10', '2030-06-20') }

          context "(after clean)" do
            before { clean.clean! }

            it "keeps the Timetable" do
              expect(timetable).to exist_in_database
            end

            it "keeps the Vehicle Journey" do
              expect(vehicle_journey).to exist_in_database
            end

            it "keeps the Journey Pattern" do
              expect(vehicle_journey.journey_pattern).to exist_in_database
            end

            it "keeps the Route" do
              expect(vehicle_journey.route).to exist_in_database
            end

            it "changes to the Vehicle Journey operating period to 2030-06-01..2030-06-09 and 2030-06-21..2030-06-30" do
              expect(vehicle_journey.reload.operating_periods).to contain_exactly(
                                                             an_object_having_attributes(range: period('2030-06-01', '2030-06-09')),
                                                             an_object_having_attributes(range: period('2030-06-21', '2030-06-30')),
                                                           )
            end
          end

          it "doesn't change to the Timetable validity period" do
            expect { clean.clean! }.to_not change(timetable, :validity_period)
          end
        end

        context "when the clean range is 2030-06-01..2030-06-30" do
          let(:clean) { Clean::InPeriod.new scope, period('2030-06-01', '2030-06-30') }
          before { clean.clean! }

          it "removes the Timetable" do
            expect(timetable).to_not exist_in_database
          end

          it "removes the Vehicle Journey" do
            expect(vehicle_journey).to_not exist_in_database
          end

          it "removes the Journey Pattern" do
            expect(referential.journey_patterns).to be_empty
          end

          it "removes the Route" do
            expect(referential.routes).to be_empty
          end
        end
      end

      context "when the scope selects the effective line" do
        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), line }

        context "when the clean range is 2030-06-10..2030-06-20" do
          let(:clean) { Clean::InPeriod.new scope, period('2030-06-10', '2030-06-20') }

          context "(after clean)" do
            before { clean.clean! }

            it "keeps the Timetable" do
              expect(timetable).to exist_in_database
            end

            it "keeps the Vehicle Journey" do
              expect(vehicle_journey).to exist_in_database
            end

            it "keeps the Journey Pattern" do
              expect(vehicle_journey.journey_pattern).to exist_in_database
            end

            it "keeps the Route" do
              expect(vehicle_journey.route).to exist_in_database
            end

            it "changes to the Vehicle Journey operating period to 2030-06-01..2030-06-09 and 2030-06-21..2030-06-30" do
              expect(vehicle_journey.reload.operating_periods).to contain_exactly(
                                                             an_object_having_attributes(range: period('2030-06-01', '2030-06-09')),
                                                             an_object_having_attributes(range: period('2030-06-21', '2030-06-30')),
                                                           )
            end
          end

          it "doesn't change to the Timetable validity period" do
            expect { clean.clean! }.to_not change(timetable, :validity_period)
          end
        end

        context "when the clean range is 2030-06-01..2030-06-30" do
          let(:clean) { Clean::InPeriod.new scope, period('2030-06-01', '2030-06-30') }
          before { clean.clean! }

          it "removes the Timetable" do
            expect(timetable).to_not exist_in_database
          end

          it "removes the Vehicle Journey" do
            expect(vehicle_journey).to_not exist_in_database
          end

          it "removes the Journey Pattern" do
            expect(referential.journey_patterns).to be_empty
          end

          it "removes the Route" do
            expect(referential.routes).to be_empty
          end
        end

        context "when the clean range is 2030-05-01..2030-05-31" do
          let(:clean) { Clean::InPeriod.new scope, period('2030-05-01', '2030-05-31') }
          before { clean.clean! }

          it "keeps the Timetable" do
            expect(timetable).to exist_in_database
          end

          it "keeps the Vehicle Journey" do
            expect(vehicle_journey).to exist_in_database
          end

          it "keeps the Journey Pattern" do
            expect(vehicle_journey.journey_pattern).to exist_in_database
          end

          it "keeps the Route" do
            expect(vehicle_journey.route).to exist_in_database
          end

          it "doesn't change the Vehicle Journey operation periods" do
            expect { clean.clean! ; vehicle_journey.reload }.to_not change(vehicle_journey, :operating_periods)
          end
        end
      end

      context "when the scope selects another line" do
        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), context.line(:other) }

        context "when the clean range is 2030-06-01..2030-06-30" do
          let(:clean) { Clean::InPeriod.new scope, period('2030-06-01', '2030-06-30') }
          before { clean.clean! }

          it "keeps the Timetable" do
            expect(timetable).to exist_in_database
          end

          it "keeps the Vehicle Journey" do
            expect(vehicle_journey).to exist_in_database
          end

          it "keeps the Journey Pattern" do
            expect(vehicle_journey.journey_pattern).to exist_in_database
          end

          it "keeps the Route" do
            expect(vehicle_journey.route).to exist_in_database
          end

          it "doesn't change the Vehicle Journey operation periods" do
            expect { clean.clean! ; vehicle_journey.reload }.to_not change(vehicle_journey, :operating_periods)
          end
        end
      end
    end
  end
end

RSpec.describe Clean::ServiceCount::InPeriod do
  let(:context) do
    Chouette.create do
      line :scoped
      line :other
      referential lines: [ :scoped ] do
        journey_pattern
      end
    end
  end
  let(:referential) { context.referential }
  before { referential.switch }

  let(:line) { journey_pattern.route.line }
  let(:journey_pattern) { context.journey_pattern }

  let!(:service_count) do
    ServiceCount.create!(
      journey_pattern_id: journey_pattern.id,
      route_id: journey_pattern.route_id,
      line_id: journey_pattern.route.line_id,
      date: service_count_date,
      count: 42
    )
  end

  def period(from, to)
    Range.new Date.parse(from), Date.parse(to)
  end

  describe "#clean!" do
    before { clean.clean! }

    context "when the clean range is 2030-06-10..2030-06-20" do
      let(:clean) { Clean::ServiceCount::InPeriod.new scope, period('2030-06-10', '2030-06-20') }

      context "when the scope is the whole Referential (no restriction)" do
        let(:scope) { Clean::Scope::Referential.new(referential) }

        context "when the Service Count is on 2030-06-15" do
          let(:service_count_date) { Date.parse '2030-06-15' }

          it "deletes this Service Count" do
            expect(service_count).to_not exist_in_database
          end
        end

        context "when the Service Count is on 2030-06-09" do
          let(:service_count_date) { Date.parse '2030-06-09' }

          it "keeps this Service Count" do
            expect(service_count).to exist_in_database
          end
        end

        context "when the Service Count is on 2030-06-21" do
          let(:service_count_date) { Date.parse '2030-06-21' }

          it "keeps this Service Count" do
            expect(service_count).to exist_in_database
          end
        end
      end

      context "when the scope selects the effective line" do
        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), line }

        context "when the Service Count is on 2030-06-15" do
          let(:service_count_date) { Date.parse '2030-06-15' }

          it "deletes this Service Count" do
            expect(service_count).to_not exist_in_database
          end
        end

        context "when the Service Count is on 2030-06-09" do
          let(:service_count_date) { Date.parse '2030-06-09' }

          it "keeps this Service Count" do
            expect(service_count).to exist_in_database
          end
        end

        context "when the Service Count is on 2030-06-21" do
          let(:service_count_date) { Date.parse '2030-06-21' }

          it "keeps this Service Count" do
            expect(service_count).to exist_in_database
          end
        end
      end

      context "when the scope selects another line" do
        let(:scope) { Clean::Scope::Line.new Clean::Scope::Referential.new(referential), context.line(:other) }

        context "when the Service Count is on 2030-06-15" do
          let(:service_count_date) { Date.parse '2030-06-15' }

          it "keeps this Service Count" do
            expect(service_count).to exist_in_database
          end
        end

        context "when the Service Count is on 2030-06-09" do
          let(:service_count_date) { Date.parse '2030-06-09' }

          it "keeps this Service Count" do
            expect(service_count).to exist_in_database
          end
        end

        context "when the Service Count is on 2030-06-21" do
          let(:service_count_date) { Date.parse '2030-06-21' }

          it "keeps this Service Count" do
            expect(service_count).to exist_in_database
          end
        end
      end
    end
  end
end

RSpec.describe Clean::VehicleJourney::NullifyCompany do
  subject { described_class.new(referential).clean! }

  let(:context) do
    Chouette.create do
      company :first
      company :second

      referential do
        vehicle_journey :first, company: :first
        vehicle_journey :second, company: :second
      end
    end
  end

  let(:first_company) { context.company(:first) }
  let(:second_company) { context.company(:second) }

  let(:second_vehicle_journey) { context.vehicle_journey(:second) }

  let(:referential) { context.referential }

  before do
    referential.switch
  end

  context 'when all vehicle journeys are associated with companies' do
    it do
      expect { subject }.to_not(change { referential.vehicle_journeys.map(&:company_id) })
    end
  end

  context 'when a company is deleted' do
    it do
      second_company.delete

      expect { subject }.to change { second_vehicle_journey.reload.company_id }.from(second_company.id).to(nil)
    end
  end
end