RSpec.describe Export::Ara do
  describe "a whole export" do
    let(:context) do
      Chouette.create do
        organisation :owner, features: %w{export_ara_stop_visits}
        workbench organisation: :owner do
          time_table :default
          vehicle_journey time_tables: [:default]
        end
      end
    end

    subject(:export) do
      Export::Ara.create! workbench: context.workbench,
                          workgroup: context.workgroup,
                          referential: context.referential,
                          name: "Test",
                          creator: "test"
    end

    before do
      export.export
      export.reload
    end

    it { is_expected.to be_successful }

    describe "file" do
      # TODO Use Ara::File to read the file
      subject { export.file.read.split("\n") }
      it { is_expected.to have_attributes(size: 48) }
    end
  end

  describe "Stops export" do

    describe Export::Ara::Stops::Decorator do
      subject(:decorator) { described_class.new(stop_area) }
      let(:stop_area) { Chouette::StopArea.new }

      describe "#parent_uuid" do
        subject { decorator.parent_uuid }

        context "when StopArea parent isn't defined" do
          before { stop_area.parent = nil }

          it { is_expected.to be_nil }
        end

        context "when StopArea parent objectid is 'test:StopArea:uuid'" do
          before { stop_area.parent = Chouette::StopArea.new(objectid: "test:StopArea:uuid") }

          it { is_expected.to eq("uuid")  }
        end
      end

      describe "#ara_attributes" do
        subject { decorator.ara_attributes }

        context "when #parent_uuid is 'uuid'" do
          before { allow(decorator).to receive(:parent_uuid).and_return("uuid") }
          it { is_expected.to include(parent_id: 'uuid')}
        end
      end
    end

    let(:export_context) { double stop_area_referential: context.stop_area_referential }
    let(:target) { [] }
    subject(:part) { Export::Ara::Stops.new export_scope: scope, target: target, context: export_context }
    let(:scope) { double stop_areas: context.stop_area_referential.stop_areas, codes: context.workgroup.codes }

    describe "#stop_areas" do
      subject { part.stop_areas }

      context "when a StopArea has a parent" do
        let(:context) do
          Chouette.create do
            stop_area :parent, area_type: Chouette::AreaType::STOP_PLACE.to_s
            stop_area :exported, parent: :parent
          end
        end

        let(:stop_area) { context.stop_area(:exported) }
        let(:parent) { stop_area.parent }

        it "includes both Stop Area and its parent" do
          is_expected.to include(stop_area, parent)
        end
      end
    end

    context "when two Stop Areas are exported" do
      let(:context) do
        Chouette.create { stop_area(:first) ; stop_area(:other) }
      end

      let(:stop_area) { context.stop_area(:first ) }
      let(:other_stop_area) { context.stop_area(:other) }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      describe "the Ara File target" do
        subject { part.export! ; target }
        it { is_expected.to match_array([an_instance_of(Ara::StopArea)]*2) }

        context "when one of the Stop Area has a registration number 'dummy'" do
          before { stop_area.update registration_number: "dummy" }
          it { is_expected.to include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when all Stop Area has a registration number 'dummy'" do
          before { scope.stop_areas.update_all registration_number: "dummy" }
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when one of the Stop Area has a code 'test': 'dummy" do
          before { stop_area.codes.create!(code_space: code_space, value: "dummy") }
          it { is_expected.to include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end

        context "when all Stop Areas has a code 'test': 'dummy" do
          before do
            scope.stop_areas.each do |stop_area|
              stop_area.codes.create! code_space: code_space, value: "dummy"
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end
      end
    end
  end

  describe "Lines export" do
    context "when two Lines are exported" do
      let(:context) do
        Chouette.create { line(:first) ; line(:other) }
      end

      let(:line) { context.line(:first ) }
      let(:other_line) { context.line(:other) }

      let(:scope) { double lines: context.line_referential.lines, codes: context.workgroup.codes }
      let(:target) { [] }

      let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

      let(:part) { Export::Ara::Lines.new export_scope: scope, target: target }

      describe "the Ara File target" do
        subject { part.export! ; target }
        it { is_expected.to match_array([an_instance_of(Ara::Line)]*2) }

        context "when one of the Line has a registration number 'dummy'" do
          before { line.update registration_number: "dummy" }
          it { is_expected.to include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when all Line has a registration number 'dummy'" do
          before { scope.lines.update_all registration_number: "dummy" }
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"external" => "dummy"})) }
        end

        context "when one of the Line has a code 'test': 'dummy" do
          before { line.codes.create!(code_space: code_space, value: "dummy") }
          it { is_expected.to include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end

        context "when all Lines has a code 'test': 'dummy" do
          before do
            scope.lines.each do |line|
              line.codes.create! code_space: code_space, value: "dummy"
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end
      end
    end
  end

  describe "VehicleJourneys export" do
    subject { part.export! ; target }

    let(:referential) { context.referential }
    before { referential.switch }

    let(:vehicle_journey) { context.vehicle_journey(:first ) }
    let(:other_vehicle_journey) { context.vehicle_journey(:other) }

    let(:scope) { referential }
    let(:target) { [] }

    let(:code_space) { context.workgroup.code_spaces.create! short_name: 'test' }

    let(:part) { Export::Ara::VehicleJourneys.new export_scope: scope, target: target }

    context 'when one Vehicle Journey is exported' do
      let(:context) do
        Chouette.create { vehicle_journey(:first) }
      end

      describe 'the Ara File target' do
        it { is_expected.to match_array([an_instance_of(Ara::VehicleJourney)]) }

        it 'contains a Vehicle journey having a direction_type attribute' do
          expect(subject.first).to respond_to(:direction_type)
        end
      end
    end

    context "when two Vehicle Journeys are exported" do
      let(:context) do
        Chouette.create { vehicle_journey(:first) ; vehicle_journey(:other) }
      end

      describe "the Ara File target" do
        it { is_expected.to match_array([an_instance_of(Ara::VehicleJourney)]*2) }

        context "when one of the Vehicle Journey has a code 'test': 'dummy" do
          before { vehicle_journey.codes.create!(code_space: code_space, value: "dummy") }
          it { is_expected.to include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end

        context "when all Vehicle Journeys has a code 'test': 'dummy" do
          before do
            scope.vehicle_journeys.each do |vehicle_journey|
              vehicle_journey.codes.create! code_space: code_space, value: "dummy"
            end
          end
          it { is_expected.to_not include(an_object_having_attributes(objectids: {"test" => "dummy"})) }
        end
      end
    end
  end

  describe "StopVisit export" do
    context "when Stop Visits are exported" do
      let(:context) do
        Chouette.create { vehicle_journey }
      end
      let(:target) { [] }
      let(:referential) { context.referential }
      let(:vehicle_journey) { context.vehicle_journey }

      let(:part) { Export::Ara::StopVisits.new export_scope: referential, target: target }

      before { referential.switch }

      describe "the Ara File target" do
        subject { part.export! ; target }

        let(:at_stops_count) { vehicle_journey.vehicle_journey_at_stops.count }

        it { is_expected.to match_array([an_instance_of(Ara::StopVisit)] * at_stops_count) }

        describe Export::Ara::StopVisits::Decorator do

          let(:vehicle_journey_at_stop) {vehicle_journey.vehicle_journey_at_stops.first }
          let(:stop_visit_decorator) { Export::Ara::StopVisits::Decorator.new vehicle_journey_at_stop }

          let(:experted_attributes) do
            an_object_having_attributes({
              schedules: [{
                "Kind" => "aimed",
                "ArrivalTime" => "2000-01-01T19:01:00+00:00",
                "DepartureTime" => "2000-01-01T15:01:00+00:00"
              }],
              passage_order: "0"
            })
          end

          before do
            vehicle_journey_at_stop.update(
              arrival_time: "2000-01-01T19:01:00+000".to_datetime,
              departure_time: "2000-01-01T15:01:00+0000".to_datetime
            )
            vehicle_journey_at_stop.stop_point.update position: 0
          end

          it "should create stop_visits with the correct attributes" do
            expect([stop_visit_decorator.ara_model]).to include(experted_attributes)
          end
        end
      end
    end
  end

end
