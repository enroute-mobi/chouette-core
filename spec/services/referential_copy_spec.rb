RSpec.describe ReferentialCopy do
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

  let(:referential_copy){ ReferentialCopy.new(source: referential, target: target)}

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

  context "#copy_time_tables" do
    let!(:time_table){
      referential.switch do
        create(:time_table)
      end
    }

    it "should copy the time_tables" do
      referential.switch
      route = create :route, line: referential.lines.last
      create :vehicle_journey, journey_pattern: route.full_journey_pattern, time_tables: [time_table]
      expect{ referential_copy.send(:copy_time_tables) }.to change{ target.switch{ Chouette::TimeTable.count } }.by 1
      new_timetable = target.switch{ Chouette::TimeTable.last }
      expect(referential_copy.send(:clean_attributes_for_copy, new_timetable)).to eq referential_copy.send(:clean_attributes_for_copy, time_table)
      expect(new_timetable.checksum).to eq time_table.checksum
    end
  end

  context "#copy_purchase_windows" do
    let!(:purchase_window){
      referential.switch do
        create(:purchase_window)
      end
    }

    it "should copy the purchase_windows" do
      referential.switch
      route = create :route, line: referential.lines.last
      create :vehicle_journey, journey_pattern: route.full_journey_pattern, purchase_windows: [purchase_window]
      expect{ referential_copy.send(:copy_purchase_windows) }.to change{ target.switch{ Chouette::PurchaseWindow.count } }.by 1
      new_purchase_window = target.switch{ Chouette::PurchaseWindow.last }
      expect(referential_copy.send(:clean_attributes_for_copy, new_purchase_window)).to eq referential_copy.send(:clean_attributes_for_copy, purchase_window.reload)
      expect(new_purchase_window.checksum).to eq purchase_window.checksum
    end
  end

end

RSpec.describe ReferentialCopy do

  describe "JourneyPatternCoursesByDate copy" do

    let(:context) do
      Chouette.create do
        referential :source do
          journey_pattern
        end
        referential :target, with_metadatas: false, archived_at: Time.now
      end
    end

    let(:source) { context.referential(:source) }

    let!(:source_journey_pattern_courses_by_day) do
      source.switch do
        journey_pattern = source.journey_patterns.first
        route = journey_pattern.route

        journey_pattern.courses_stats.create! line: route.line, route: route, count: 42, date: Time.zone.today
      end
    end

    let(:target) { context.referential(:target) }

    let(:referential_copy) { ReferentialCopy.new source: source, target: target }

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
        source_attributes = {
          count: source_journey_pattern_courses_by_day.count,
          date: source_journey_pattern_courses_by_day.date
        }
        is_expected.to have_attributes(source_attributes)
      end

    end

  end

end
