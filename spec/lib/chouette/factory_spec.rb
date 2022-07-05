
RSpec.describe Chouette::Factory do

  it "should raise error when type isn't known" do
    expect {
      Chouette::Factory.create { dummy }
    }.to raise_error
  end

  it "should create workgroup" do
    expect {
      Chouette::Factory.create { workgroup }
    }.to(change { Workgroup.count })
  end

  it "should create line_referential" do
    expect {
      Chouette::Factory.create do
        workgroup do
          line_referential
        end
      end
    }.to(change { LineReferential.count })
  end

  describe "Retrieve instances" do

    describe "context.instance(:name)" do

      it "should return the instance created with this name" do
        context = Chouette::Factory.create { line :first }
        expect(context.instance(:first)).to be_kind_of(Chouette::Line)
      end

      it "should return nil when the instance matches" do
        context = Chouette::Factory.create { }
        expect(context.instance(:dummy)).to be_nil
      end

      it "should raise an error when several instances" do
        context = Chouette::Factory.create do
          line :first
          stop_area :first
        end

        expect { context.instance(:first) }.to raise_error(Chouette::Factory::Error)
      end

    end

    describe "context.line" do

      it "should return the line instance" do
        context = Chouette::Factory.create { line }
        expect(context.line).to be_kind_of(Chouette::Line)
      end

      it "should return NameError when the instance matches" do
        context = Chouette::Factory.create { }
        expect { context.line }.to raise_error(NameError)
      end

      it "should raise an error when several instances" do
        context = Chouette::Factory.create do
          line
          line
        end

        expect { context.line }.to raise_error(Chouette::Factory::Error)
      end

    end

    describe "context.lines" do

      it "should return the lines instance" do
        context = Chouette::Factory.create { line ; line }
        expect(context.lines).to all(be_kind_of(Chouette::Line))
      end

      it "should return NameError when no instance match" do
        context = Chouette::Factory.create { }
        expect { context.lines }.to raise_error(NameError)
      end

    end

  end

  describe "Define model Attributes" do
    describe '{ line name: "RER A", transport_mode: "rail" }' do
      before do
        Chouette::Factory.create do
          line name: "RER A", transport_mode: "rail"
        end
      end

      let(:line) { Chouette::Line.first }

      it "should create a Line with name 'RER A'" do
        expect(line.name).to eq('RER A')
      end

      it "should create a Line with name 'RER A'" do
        expect(line.transport_mode).to eq('rail')
      end

    end
  end

  describe "Context sharing" do

    describe %{{
      line_referential :referential_1 do
        line :first
      end
      line_referential :referential_2 do
        line :second
      end
    }} do
      let(:context) do
        Chouette::Factory.create do
          line_referential :referential_1
          line_referential :referential_2
        end
      end

      it "should create two Workgroups" do
        expect {
          context
        }.to change { Workgroup.count }.by(2)
      end

      it "should create two LineReferentials" do
        expect {
          context
        }.to change { LineReferential.count }.by(2)
      end

      it "should create the two LineReferentials into two Workgroups" do
        expect(context.instance(:referential_1).workgroup).to_not eq(context.instance(:referential_2).workgroup)
      end
    end

    describe %{{
      line :first
      line :second
    }} do
      let(:context) do
        Chouette::Factory.create do
          line :first
          line :second
        end
      end

      it "should create two lines in the same LineReferential" do
        expect(context.instance(:first).line_referential).to eq(context.instance(:second).line_referential)
      end

      it "should create a single LineReferential" do
        expect {
          context
        }.to change { LineReferential.count }.by(1)
      end

      it "should create a single Workgroup" do
        expect {
          context
        }.to change { Workgroup.count }.by(1)
      end
    end

    describe %{{
      line_provider :parent do
        line :first
        line :second
      end
    }} do
      let(:context) do
        Chouette::Factory.create do
          line_provider :parent do
            line :first
            line :second
          end
        end
      end

      it "should create two lines in the same LineProvider" do
        expect(context.instance(:first).line_provider).to eq(context.instance(:parent))
        expect(context.instance(:first).line_provider).to eq(context.instance(:parent))
      end
    end

    describe %{{
      route :first
      route :second
    }} do
      let!(:context) do
        Chouette::Factory.create do
          route :first
          route :second
        end
      end

      let(:referential) { context.referential }

      it "should create two Routes in the same Referential" do
        referential.switch do
          expect(referential.routes.count).to eq(2)
        end
      end
    end

  end

  describe "Referentials" do
    describe "{ referential }" do
      before do
        Chouette::Factory.create { referential }
      end

      it "should create a Referential" do
        expect(Referential.count).to eq(2)
      end

    end

    describe "{ referential name: 'Test' }" do
      let(:context) { Chouette::Factory.create { referential name: "Test" } }

      it "should create a Referential with name 'Test'" do
        expect(context.referential.name).to eq('Test')
      end
    end

    describe "{ referential :test, name: 'Test' }" do
      let(:factory) do
        Chouette::Factory.create { referential :test, name: "Test" }
      end

      let(:referential) { factory.instance :test }

      it "should create a Referential :test with name 'Test'" do
        expect(referential.name).to eq('Test')
      end
    end

    describe %{
      {
         line :first
         line :second
         referential lines: [:first, :second]
      }
    } do
      let!(:factory) do
        Chouette::Factory.create do
          line :first
          line :second
          referential lines: [:first, :second]
        end
      end

      let(:referential) { factory.referential }

      it "should create a Referential with the two lines in metadata" do
        expect(referential.lines).to contain_exactly(factory.instance(:first), factory.instance(:second))
      end
    end
  end

  describe "VehicleJourneys" do
    describe "{ vehicle_journey }" do
      let(:context) do
        Chouette::Factory.create { vehicle_journey }
      end

      let(:referential) { context.referential }

      it "should create VehicleJourney" do
        referential.switch do
          expect(Chouette::VehicleJourney.count).to eq(1)
        end
      end

      it "should create VehicleJourney with 3 stops" do
        referential.switch do
          expect(Chouette::VehicleJourney.last.vehicle_journey_at_stops.count).to eq(3)
        end
      end
    end

    describe %{{
      time_table :default
      vehicle_journey time_tables: [:default]
    }} do
      let(:context) do
        Chouette::Factory.create do
          time_table :default
          vehicle_journey time_tables: [:default]
        end
      end

      let(:referential) { context.referential }

      it "should create a TimeTable" do
        referential.switch do
          expect(Chouette::TimeTable.count).to eq(1)
        end
      end

      it "should create VehicleJourney" do
        referential.switch do
          expect(Chouette::VehicleJourney.count).to eq(1)
        end
      end

      let(:vehicle_journey) { context.vehicle_journey }
      let(:time_table) { context.time_table(:default) }

      it "should create a VehicleJourney with the TimeTable :default" do
        referential.switch do
          expect(vehicle_journey.time_tables).to eq([time_table])
        end
      end
    end
  end

  describe "Routes" do

    describe "{ route }" do

      let(:context) do
        Chouette::Factory.create do
          route
        end
      end

      let(:referential) { context.referential }

      it "should create Route" do
        referential.switch do
          expect(Chouette::Route.count).to eq(1)
        end
      end

      it "should create Route with 3 stops" do
        referential.switch do
          expect(Chouette::Route.last.stop_points.count).to eq(3)
        end
      end

    end

    describe %{
      {
         line :first
         route line: :first
      }
    } do

      let!(:context) do
        Chouette::Factory.create do
          line :first
          route line: :first
        end
      end

      let(:referential) { context.referential }
      let(:line) { context.instance(:first) }

      it "should create Route with specified line" do
        referential.switch do
          expect(context.route.line).to eq(line)
        end
      end

    end

    describe "StopPoint" do

      describe "route stop_count: 5" do

        let(:context) do
          Chouette::Factory.create do
            route stop_count: 5
          end
        end

        before { context.referential.switch }

        it "creates a Route with 5 stop points" do
          expect(context.route.stop_points.length).to eq(5)
        end

      end

    end

    describe "StopArea" do
      let(:context) do
        Chouette::Factory.create do
          stop_area :first
          stop_area :second
          stop_area :third
        end
      end

      it "creates 3 stop areas" do
        expect{context}.to change { Chouette::StopArea.count }.by(3)
      end

      it "creates a Stop Area Provider" do
        # The Workbench creates a default StopAreaProvider and the Factory creates its StopAreaProvider
        stop_area_providers = StopAreaProvider.where.not(name: Workbench::DEFAULT_PROVIDER_SHORT_NAME.capitalize)
        expect{ context }.to(change { stop_area_providers.count }.by(1))
      end

      it "each newly created object is related to the same stop area referential" do
        expect(context.stop_area(:first).stop_area_referential).to eq(context.stop_area_provider.stop_area_referential)
      end

      it "creates a stop_area_referential" do
        expect{context}.to change { StopAreaReferential.count }.by(1)
      end

      describe "attributes" do
        subject { context.stop_area }

        context "when an Area Type is specified" do
          let(:context) { Chouette::Factory.create { stop_area area_type: Chouette::AreaType::STOP_PLACE.to_s } }
          it { is_expected.to have_attributes(area_type: Chouette::AreaType::STOP_PLACE.to_s) }
        end
      end
    end

    describe %{
        route with_stops: false {
          stop_point
          stop_point
        }
      } do

      let(:context) do
        Chouette::Factory.create do
          stop_area :departure
          stop_area :arrival

          route with_stops: false do
            stop_point :departure, stop_area: :departure
            stop_point
            stop_point :arrival, stop_area: :arrival
          end
        end
      end

      before { context.referential.switch }

      it "creates a Route with 3 stop points" do
        expect(context.route.stop_points.length).to eq(3)
      end

      it "creates a StopPoint :departure with StopArea :departure" do
        expect(context.stop_point(:departure).stop_area).to eq(context.stop_area(:departure))
      end

      it "creates a StopPoint :arrival with StopArea :arrival" do
        expect(context.stop_point(:arrival).stop_area).to eq(context.stop_area(:arrival))
      end

    end

  end


  describe "TimeTables" do

    let(:a_month_from_now) { Time.zone.today..1.month.from_now.to_date }

    describe "{ time_table }" do
      let(:context) do
        Chouette::Factory.create do
          time_table
        end
      end

      let(:referential) { context.referential }
      let(:time_table) { context.time_table }

      it "should create TimeTable with default period" do
        referential.switch do
          expect(Chouette::TimeTable.count).to eq(1)

          expect(time_table.periods.count).to eq(1)

          period = time_table.periods.first
          expect(period.range).to eq(a_month_from_now)
        end
      end
    end

    describe "{ time_table dates_excluded: Time.zone.today }" do
      let(:context) do
        Chouette::Factory.create do
          time_table dates_excluded: Time.zone.today
        end
      end

      let(:referential) { context.referential }
      let(:time_table) { context.time_table }

      it "should create TimeTable with default period" do
        referential.switch do
          expect(Chouette::TimeTable.count).to eq(1)

          expect(time_table.periods.count).to eq(1)

          period = time_table.periods.first
          expect(period.range).to eq(a_month_from_now)
        end
      end

      it "should create TimeTable with specified excluded date" do
        referential.switch do
          expect(time_table.dates.count).to eq(1)

          date = time_table.dates.first
          expect(date.in_out).to be_falsy
          expect(date.date).to eq(Time.zone.today)
        end
      end
    end

    describe "{ time_table dates_included: Time.zone.today }" do
      let(:context) do
        Chouette::Factory.create do
          time_table dates_included: Time.zone.today
        end
      end

      let(:referential) { context.referential }
      let(:time_table) { context.time_table }

      it "should create TimeTable with default period" do
        referential.switch do
          expect(Chouette::TimeTable.count).to eq(1)

          expect(time_table.periods.count).to eq(1)
          period = time_table.periods.first
          expect(period.range).to eq(a_month_from_now)
        end
      end

      it "should create TimeTable with specified included date" do
        referential.switch do
          expect(time_table.dates.count).to eq(1)

          date = time_table.dates.first
          expect(date.in_out).to be_truthy
          expect(date.date).to eq(Time.zone.today)
        end
      end
    end

  end

  describe "Shapes" do

    describe "{ shape_referential }" do
      it "should create a ShapeReferential" do
        expect { Chouette.create { shape_referential } }.to change { ShapeReferential.count }.by(1)
      end
    end

    describe "{ shape }" do
      it "should create a Shape" do
        expect { Chouette.create { shape } }.to change { Shape.count }.by(1)
      end
    end

  end

  describe "Chouette.create shortcut" do

    let(:context) { Chouette.create { line } }

    it "should returns Chouette::Factory" do
      expect(context).to be_kind_of(Chouette::Factory)
    end

    it "should an initialized factory" do
      expect(context.line).to_not be_nil
    end

  end

end
