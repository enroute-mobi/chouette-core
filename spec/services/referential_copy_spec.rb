describe ReferentialCopy do
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential_metadata){ create(:referential_metadata, lines: line_referential.lines.limit(3)) }
  let(:referential){
    create :referential,
      workbench: workbench,
      organisation: workbench.organisation,
      metadatas: [referential_metadata]
  }

  let(:target){
    create :referential,
      workbench: workbench,
      organisation: workbench.organisation,
      metadatas: [create(:referential_metadata)]
  }

  let(:referential_copy) { ReferentialCopy.new(source: referential, target: target) }

  before(:each) do
    4.times { create :line, line_referential: line_referential, company: company, network: nil }
    10.times { create :stop_area, stop_area_referential: stop_area_referential }
    target.switch do
      route = create :route, line: line_referential.lines.last
      journey_pattern = route.full_journey_pattern
      create :vehicle_journey, journey_pattern: journey_pattern
    end
  end

  context "#copy" do
    context "with no data" do
      it "should succeed" do
        referential_copy.copy
        expect(referential_copy.status).to eq :successful
        expect(referential_copy.last_error).to be_nil
      end
    end

    context "with data" do
      before(:each){
        referential.switch do
          create(:route, line: referential.lines.first)
        end
      }
      it "should succeed" do
        referential_copy.copy
        expect(referential_copy.status).to eq :successful
        expect(referential_copy.last_error).to be_nil
      end

      context "with an error" do
        before(:each){
          allow_any_instance_of(Chouette::Route).to receive(:save!).and_raise("boom")
        }

        it "should fail" do
          referential_copy.copy
          expect(referential_copy.status).to eq :failed
          expect(referential_copy.last_error).to match(/boom/)
          expect(referential_copy.last_error).to match(/Chouette::Route/)
        end
      end
    end
  end

  context "#lines" do
    it "should use referential lines" do
      lines = referential.lines.to_a
      expect(referential).to receive(:lines).and_call_original
      expect(referential_copy.send(:lines).to_a).to eq lines
    end
  end

  context "#copy_metadatas" do
    it "should copy metadatas" do
      expect{referential_copy.send :copy_metadatas}.to change{target.metadatas.count}.by 1
      target_metadata = target.metadatas.last
      expect(target_metadata.lines).to eq referential_metadata.lines
      expect(target_metadata.periodes).to eq referential_metadata.periodes
    end

    context "run twice" do
      it "should copy metadatas only once" do
        referential_copy.send :copy_metadatas
        expect{referential_copy.send :copy_metadatas}.to change{target.metadatas.count}.by 0
        target_metadata = target.metadatas.last
        expect(target_metadata.lines).to eq referential_metadata.lines
        expect(target_metadata.periodes).to eq referential_metadata.periodes
      end
    end

    context "with existing overlapping periodes" do
      it "should create a new metadata nonetheless" do
        referential
        target
        overlapping_metadata = target.metadatas.last
        period = referential_metadata.periodes.last
        overlapping_metadata.periodes = [(period.max-1.day..period.max+1.day)]
        overlapping_metadata.line_ids = referential_metadata.line_ids
        overlapping_metadata.save!
        expect{referential_copy.send :copy_metadatas}.to change{target.metadatas.count}.by 1
        target_metadata = target.metadatas.reload.order(:created_at).last
        expect(target_metadata.lines).to eq referential_metadata.lines
        expect(target_metadata.periodes).to eq [period]
      end
    end
  end

  context "#copy_footnotes" do
    let!(:footnote){
      referential.switch do
        create(:footnote, line: line_referential.lines.first)
      end
    }

    it "should copy the footnotes" do
      referential.switch
      expect{ referential_copy.send(:copy_footnotes, footnote.line.reload) }.to change{ target.switch{ Chouette::Footnote.count } }.by 1
      new_footnote = target.switch{ Chouette::Footnote.last }
      expect(referential_copy.send(:clean_attributes_for_copy, footnote)).to eq referential_copy.send(:clean_attributes_for_copy, new_footnote)
    end
  end

  context "#copy_route" do
    let!(:route) do
      referential.switch do
        create(:route, :with_opposite)
      end
    end

    let(:opposite_route) do
      referential.switch do
        route.opposite_route
      end
    end

    let(:line) do
      route.line
    end

    it "should copy the routes" do
      referential.switch
      expect(opposite_route).to be_present
      expect{ referential_copy.send(:copy_routes, line) }.to change{ target.switch{ Chouette::Route.count } }.by 2
      new_route = target.switch{ Chouette::Route.find_by(objectid: route.objectid) }
      expect(referential_copy.send(:clean_attributes_for_copy, new_route)).to eq referential_copy.send(:clean_attributes_for_copy, route)
      new_opposite_route = target.switch{ route.opposite_route }
      expect(new_route.checksum).to eq route.checksum
      expect(new_opposite_route.checksum).to eq opposite_route.checksum
    end

  end

end

describe ReferentialCopy do

  let(:source) { context.referential(:source) }
  let(:target) { context.referential(:target) }

  let(:referential_copy) { ReferentialCopy.new source: source, target: target }

  describe "metadatas copy" do

    let(:context) do
      Chouette.create do
        referential :source
        referential :target, with_metadatas: false, archived_at: Time.now
      end
    end

    it "contains the same metadata count" do
      expect {
        referential_copy.copy

        # Save the target referential to ensure unsaved metadatas (after copy) are persisted (see CHOUETTE-691)
        target.save!
      }.to change { target.metadatas.count }
             .from(0).to(source.metadatas.count)
    end

    it "keep unchanged metadatas created_at timestamp" do
      original_timestamp = Time.now.beginning_of_day
      source.metadatas.update_all created_at: original_timestamp

      referential_copy.copy

      expect(target.metadatas).to all(have_attributes(created_at: original_timestamp))
    end

    it "use the source Referential as referential_source" do
      referential_copy.copy

      expect(target.metadatas).to all(have_attributes(referential_source_id: source.id))
    end

  end

  describe "when a line is not included in the copy" do

    let(:context) do
      Chouette.create do
        line :included
        line :excluded

        referential :source, lines: [ :included, :excluded ] do
          route(line: :included) { vehicle_journey }
          route(line: :excluded) { vehicle_journey }
        end
        referential :target, with_metadatas: false, archived_at: Time.now
      end
    end

    let(:referential_copy) do
      ReferentialCopy.new source: source,
                          target: target,
                          lines: target.lines.where(id: context.line(:included))
    end
    let(:excluded_line) { context.line :excluded }

    context "after copy" do
      before { referential_copy.copy }

      describe "the target referential" do
        before { target.switch }

        it "doesn't contain route associated to the excluded line" do
          expect(target.routes.where(line: excluded_line)).to be_empty
        end

        it "contain metadata associated to the excluded line (#warning)" do
          expect(target.metadatas.include_lines(excluded_line.id)).to_not be_empty
        end
      end
    end
  end

  describe "Vehicle Journey copy" do

    let(:context) do
      Chouette.create do
        referential :source do
          3.times { vehicle_journey }
        end
        referential :target, with_metadatas: false, archived_at: Time.now
      end
    end

    it "contains the same VehicleJourney count" do
      expect {
        referential_copy.copy
      }.to change { target.switch { target.vehicle_journeys.count } }
             .from(0).to( source.switch { source.vehicle_journeys.count } )
    end

    it "contains the same VehicleJourneyAtStops count" do
      expect {
        referential_copy.copy
      }.to change { target.switch { target.vehicle_journey_at_stops.count } }
             .from(0).to( source.switch { source.vehicle_journey_at_stops.count } )
    end

  end

  describe "several copies" do

    let(:context) do
      Chouette.create do
        referential :source do
          3.times { vehicle_journey }
        end
        referential :second_source do
          3.times { vehicle_journey }
        end
        referential :target, with_metadatas: false, archived_at: Time.now
      end
    end

    let(:second_source) { context.referential(:second_source) }
    let(:second_referential_copy) { ReferentialCopy.new source: second_source, target: target }

    it "contains the same VehicleJourney count" do
      expected_vehicle_journey_count =
        source.switch { source.vehicle_journeys.count } +
        second_source.switch { second_source.vehicle_journeys.count }

      expect {
        referential_copy.copy
        second_referential_copy.copy
      }.to change { target.switch { target.vehicle_journeys.count } }
             .from(0).to(expected_vehicle_journey_count)
    end

  end

  describe "TimeTable copy" do

    let(:context) do
      Chouette.create do
        referential :source do
          time_table :first, dates_excluded: Time.zone.today + 10

          3.times { vehicle_journey time_tables: [:first] }
        end
        referential :target, with_metadatas: false, archived_at: Time.now
      end
    end

    it "contains the same TimeTable count" do
      expect {
        referential_copy.copy
      }.to change { target.switch { target.time_tables.count } }
             .from(0).to( source.switch { target.time_tables.count } )
    end

    it "contains the same TimeTableDate count" do
      expect {
        referential_copy.copy
      }.to change { target.switch { target.time_table_dates.count } }
             .from(0).to( source.switch { target.time_table_dates.count } )
    end

    it "contains the same TimeTablePeriod count" do
      expect {
        referential_copy.copy
      }.to change { target.switch { target.time_table_periods.count } }
             .from(0).to( source.switch { target.time_table_periods.count } )
    end

    describe "the TimeTable in target referential" do

      subject { target.switch { target.time_tables.first } }

      let(:source_time_table) { source.switch { source.time_tables.first } }

      before { referential_copy.copy }
      around { |example| target.switch { example.run } }

      it "has the same period(s)" do
        expect(subject.periods.map(&:range)).to eq(source_time_table.periods.map(&:range))
      end

      it "has the same date(s)" do
        expect(subject.dates.map(&:date)).to eq(source_time_table.dates.map(&:date))
      end

    end

  end

  describe "JourneyPatternCoursesByDate copy" do

    let(:context) do
      Chouette.create do
        referential :source do
          journey_pattern
        end
        referential :target, with_metadatas: false, archived_at: Time.now
      end
    end

    let!(:source_journey_pattern_courses_by_day) do
      source.switch do
        journey_pattern = source.journey_patterns.first
        route = journey_pattern.route

        journey_pattern.courses_stats.create! line: route.line, route: route, count: 42, date: Time.zone.today
      end
    end

    it "contains the same JourneyPatternCoursesByDate count" do
      expect {
        referential_copy.copy
      }.to change { target.switch { target.service_counts.count } }
             .from(0).to( source.switch { target.service_counts.count } )
    end

    describe "the JourneyPatternCoursesByDate in target referential" do

      subject { target.switch { target.service_counts.first } }

      before { referential_copy.copy }
      around { |example| target.switch { example.run } }

      let(:source_journey_pattern) { source.switch { source.journey_patterns.first } }
      let(:target_journey_pattern) { target.switch { target.journey_patterns.first } }

      it { is_expected.to_not be_nil }

      it "is associated to the target JourneyPattern" do
        is_expected.to have_attributes(journey_pattern_id: target_journey_pattern.id)
      end

      it "is associated to the target Route" do
        is_expected.to have_attributes(route_id: target_journey_pattern.route_id)
      end

      it "has the same date and count than the source JourneyPatternCoursesByDate" do
        is_expected.to have_same_attributes(:count, :date, than: source_journey_pattern_courses_by_day)
      end

    end
  end
end
