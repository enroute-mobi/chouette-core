RSpec.describe Export::Gtfs::Scope do
  subject(:scope) { described_class.new(initial_scope, export: export) }
  let(:export) { Export::Gtfs.new }
  let(:initial_scope) { double }

  describe 'StopAreas concerning' do
    describe '#ignore_parent_stop_places?' do
      subject { scope.ignore_parent_stop_places? }

      context 'when Export#ignore_parent_stop_places is true' do
        before { export.ignore_parent_stop_places = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#ignore_parent_stop_places is false' do
        before { export.ignore_parent_stop_places = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#prefer_referent_stop_areas?' do
      subject { scope.prefer_referent_stop_areas? }

      context 'when Export#prefer_referent_stop_areas is true' do
        before { export.prefer_referent_stop_area = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#prefer_referent_stop_areas is false' do
        before { export.prefer_referent_stop_area = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#scoped_stop_areas' do
      subject { scope.scoped_stop_areas }

      let(:context) do
        Chouette.create do
          stop_area :parent, name: 'Parent', area_type: Chouette::AreaType::STOP_PLACE
          stop_area :child, name: 'Child', parent: :parent
        end
      end

      let(:child) { context.stop_area :child }
      let(:parent) { context.stop_area :parent }

      let(:initial_scope) { double stop_areas: Chouette::StopArea.where(id: child) }

      context 'when ignore_parent_stop_places? is enabled' do
        before { allow(scope).to receive(:ignore_parent_stop_places?).and_return(true) }

        it { is_expected.to include(child) }
        it { is_expected.to_not include(parent) }
      end

      context 'when ignore_parent_stop_places? is disabled' do
        before { allow(scope).to receive(:ignore_parent_stop_places?).and_return(false) }

        it { is_expected.to include(child) }
        it { is_expected.to include(parent) }
      end
    end

    describe '#stop_areas' do
      subject { scope.stop_areas }

      let(:context) do
        Chouette.create do
          stop_area :referent, name: 'Referent', is_referent: true
          stop_area :particular, name: 'Particular', referent: :referent

          stop_area :other, name: 'Other'
        end
      end

      let(:particular) { context.stop_area :particular }
      let(:referent) { context.stop_area :referent }
      let(:other) { context.stop_area :other }

      before { allow(scope).to receive(:scoped_stop_areas) { Chouette::StopArea.where(id: [particular, other]) } }

      context 'when prefer_referent_stop_areas? is enabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(true) }

        it { is_expected.to include(referent) }
        it { is_expected.to_not include(particular) }

        it { is_expected.to include(other) }
      end

      context 'when prefer_referent_stop_areas? is disabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(false) }

        it { is_expected.to_not include(referent) }
        it { is_expected.to include(particular) }

        it { is_expected.to include(other) }
      end
    end

    describe '#referenced_stop_areas' do
      subject { scope.referenced_stop_areas }

      context 'when prefer_referent_stop_area? is disabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(false) }

        let(:context) do
          Chouette.create do
            stop_area
          end
        end

        let(:initial_scope) { double stop_areas: Chouette::StopArea.where(id: context.stop_area) }

        it { is_expected.to be_empty }
      end

      context 'when prefer_referent_stop_area? is enabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(true) }

        let(:context) do
          Chouette.create do
            stop_area :referent, name: 'Referent', is_referent: true
            stop_area :particular, name: 'Particular', referent: :referent

            stop_area :other
          end
        end

        let(:particular) { context.stop_area :particular }
        let(:referent) { context.stop_area :referent }
        let(:other) { context.stop_area :other }

        before { allow(scope).to receive(:scoped_stop_areas) { Chouette::StopArea.where(id: [ particular, other ]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to_not include(other) }
      end
    end

    describe '#dependencies_stop_areas' do
      subject { scope.dependencies_stop_areas }

      context 'when prefer_referent_stop_area? is disabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(false) }

        let(:context) do
          Chouette.create do
            stop_area :referent, name: 'Referent', is_referent: true
            stop_area :particular, name: 'Particular', referent: :referent
          end
        end

        let(:particular) { context.stop_area :particular }
        let(:initial_scope) { double stop_areas: Chouette::StopArea.where(id: particular) }

        it { is_expected.to include(particular) }
      end

      context 'when prefer_referent_stop_area? is enabled' do
        before { allow(scope).to receive(:prefer_referent_stop_areas?).and_return(true) }

        let(:context) do
          Chouette.create do
            stop_area :referent, name: 'Referent', is_referent: true
            stop_area :particular, name: 'Particular', referent: :referent

            stop_area :other
          end
        end

        let(:particular) { context.stop_area :particular }
        let(:referent) { context.stop_area :referent }
        let(:other) { context.stop_area :other }

        before { allow(scope).to receive(:scoped_stop_areas) { Chouette::StopArea.where(id: [ particular, other ]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to include(referent) }
        it { is_expected.to include(other) }
      end
    end

    describe '#entrances' do
      subject { scope.entrances }

      let(:context) do
        Chouette.create do
          stop_area :first

          entrance :scoped, stop_area: :first
          entrance
        end
      end

      let(:stop_area) { context.stop_area :first }
      let(:entrance) { context.entrance :scoped }

      before do
        allow(scope).to receive(:stop_area_referential) { context.stop_area_referential }

        allow(scope).to receive(:dependencies_stop_areas) do
          Chouette::StopArea.where(id: [ stop_area ])
        end
      end

      it { is_expected.to include(entrance) }
    end

    describe '#connection_links' do
      subject { scope.connection_links }

      let(:context) do
        Chouette.create do
          stop_area :first
          stop_area :other
          stop_area :other2

          connection_link departure: :first, arrival: :other
          connection_link arrival: :first, departure: :other
          connection_link :unscoped, departure: :other, arrival: :other2
        end
      end

      let(:stop_area) { context.stop_area :first }
      let(:unscoped) { context.connection_link :unscoped }

      before do
        allow(scope).to receive(:stop_area_referential) { context.stop_area_referential }

        allow(scope).to receive(:dependencies_stop_areas) do
          Chouette::StopArea.where(id: [ stop_area ])
        end
      end

      it { is_expected.to_not include(unscoped) }
    end
  end

  describe 'Lines concerning' do
    describe '#prefer_referent_lines?' do
      subject { scope.prefer_referent_lines? }

      context 'when Export#prefer_referent_lines is true' do
        before { export.prefer_referent_line = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#prefer_referent_lines is false' do
        before { export.prefer_referent_line = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#scoped_lines' do
      subject { scope.scoped_lines }

      let(:initial_scope) { double(lines: double("Initial Scope lines")) }

      it { is_expected.to eq(initial_scope.lines) }
    end

    describe '#referenced_lines' do
      subject { scope.referenced_lines }

      context 'when prefer_referent_lines? is disabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(false) }

        let(:context) do
          Chouette.create do
            line
          end
        end

        let(:initial_scope) { double lines: Chouette::Line.where(id: context.line) }

        it { is_expected.to be_empty }
      end

      context 'when prefer_referent_lines? is enabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(true) }

        let(:context) do
          Chouette.create do
            line :referent, name: 'Referent', is_referent: true
            line :particular, name: 'Particular', referent: :referent

            line :other
          end
        end

        let(:particular) { context.line :particular }
        let(:referent) { context.line :referent }
        let(:other) { context.line :other }

        before { allow(scope).to receive(:scoped_lines) { Chouette::Line.where(id: [ particular, other ]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to_not include(other) }
      end
    end

    describe '#lines' do
      subject { scope.lines }

      let(:context) do
        Chouette.create do
          line :referent, name: 'Referent', is_referent: true
          line :particular, name: 'Particular', referent: :referent

          line :other, name: 'Other'
        end
      end

      let(:particular) { context.line :particular }
      let(:referent) { context.line :referent }
      let(:other) { context.line :other }

      before { allow(scope).to receive(:scoped_lines) { Chouette::Line.where(id: [particular, other]) } }

      context 'when prefer_referent_lines? is enabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(true) }

        it { is_expected.to include(referent) }
        it { is_expected.to_not include(particular) }

        it { is_expected.to include(other) }
      end

      context 'when prefer_referent_lines? is disabled' do
        before { allow(scope).to receive(:prefer_referent_lines?).and_return(false) }

        it { is_expected.to_not include(referent) }
        it { is_expected.to include(particular) }

        it { is_expected.to include(other) }
      end
    end
  end

  describe 'Companies concerning' do
    describe '#prefer_referent_companies?' do
      subject { scope.prefer_referent_companies? }

      context 'when Export#prefer_referent_companies is true' do
        before { export.prefer_referent_company = true }

        it { is_expected.to be_truthy }
      end

      context 'when Export#prefer_referent_companies is false' do
        before { export.prefer_referent_company = false }

        it { is_expected.to be_falsy }
      end
    end

    describe '#referenced_companies' do
      subject { scope.referenced_companies }

      context 'when prefer_referent_companies? is disabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(false) }

        let(:context) do
          Chouette.create do
            company
          end
        end

        let(:initial_scope) { double companies: Chouette::Company.where(id: context.company) }

        it { is_expected.to be_empty }
      end

      context 'when prefer_referent_companies? is enabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(true) }

        let(:context) do
          Chouette.create do
            company :referent, name: 'Referent', is_referent: true
            company :particular, name: 'Particular', referent: :referent

            company :other
          end
        end

        let(:particular) { context.company :particular }
        let(:referent) { context.company :referent }
        let(:other) { context.company :other }

        before { allow(scope).to receive(:scoped_companies) { Chouette::Company.where(id: [ particular, other ]) } }

        it { is_expected.to include(particular) }
        it { is_expected.to_not include(other) }
      end
    end

    describe '#line_company_ids' do
      subject { scope.line_company_ids }

      let(:context) do
        Chouette.create do
          company :first
          company :second

          line company: :first
          line company: :first

          line :unscoped, company: :second
        end
      end

      before { allow(scope).to receive(:dependencies_lines).and_return(scoped_lines) }

      let(:scoped_lines) { context.line_referential.lines.where.not(id: unscoped_line) }
      let(:unscoped_line) { context.line :unscoped }

      let(:scoped_company) { context.company :first }

      it "contains identifiers of Company associated to scoped lines" do
        is_expected.to match_array(scoped_company.id)
      end
    end

    describe '#vehicle_journey_company_ids' do
      subject { scope.vehicle_journey_company_ids }

      let(:context) do
        Chouette.create do
          company :first
          company :second

          vehicle_journey company: :first
          vehicle_journey company: :first

          vehicle_journey :unscoped, company: :second
        end
      end

      before { context.referential.switch }
      before do
        current_scope = double(vehicle_journeys: scoped_vehicle_journeys)
        allow(scope).to receive(:current_scope).and_return(current_scope)
      end

      let(:scoped_vehicle_journeys) { context.referential.vehicle_journeys.where.not(id: unscoped_vehicle_journey) }
      let(:unscoped_vehicle_journey) { context.vehicle_journey :unscoped }

      let(:scoped_company) { context.company :first }

      it "contains identifiers of Company associated to scoped Vehicle Journeys" do
        is_expected.to match_array(scoped_company.id)
      end
    end

    describe '#company_ids' do
      subject { scope.company_ids }

      before do
        allow(scope).to receive(:line_company_ids) { [ 42 ] }
        allow(scope).to receive(:vehicle_journey_company_ids) { [ 42, 43 ] }
      end

      context 'when line_company_ids is [ 42 ] and vehicle_journey_company_ids is [ 42, 43 ]' do
        it { is_expected.to contain_exactly(42, 43) }
      end
    end

    describe '#scoped_companies' do
      subject { scope.scoped_companies }

      let(:context) do
        Chouette.create do
          company
        end
      end

      let(:company) { context.company }

      before do
        allow(scope).to receive(:company_ids) { company.id }
        allow(scope).to receive(:line_referential) { context.line_referential }
      end

      it { is_expected.to include(company) }
    end

    describe '#companies' do
      subject { scope.companies }

      let(:context) do
        Chouette.create do
          company :referent, name: 'Referent', is_referent: true
          company :particular, name: 'Particular', referent: :referent

          company :other, name: 'Other'
        end
      end

      let(:particular) { context.company :particular }
      let(:referent) { context.company :referent }
      let(:other) { context.company :other }

      before { allow(scope).to receive(:scoped_companies) { Chouette::Company.where(id: [particular, other]) } }

      context 'when prefer_referent_companies? is enabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(true) }

        it { is_expected.to include(referent) }
        it { is_expected.to_not include(particular) }

        it { is_expected.to include(other) }
      end

      context 'when prefer_referent_companies? is disabled' do
        before { allow(scope).to receive(:prefer_referent_companies?).and_return(false) }

        it { is_expected.to_not include(referent) }
        it { is_expected.to include(particular) }

        it { is_expected.to include(other) }
      end
    end
  end
end

RSpec.describe Export::Gtfs, type: [:model, :with_exportable_referential] do
  let(:gtfs_export) { create :gtfs_export, referential: exported_referential, workbench: workbench, duration: 5, prefer_referent_stop_area: true, prefer_referent_company: true}

  describe 'Company Part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:index) { export.index }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup, referential: context.referential, prefer_referent_company: true}

    let(:part) do
      Export::Gtfs::Companies.new export
    end

    before do
      context.referential.switch
      part.export!
    end

    let(:context) do
      Chouette.create do
        line_provider :first do
          company :c1, registration_number: "1", time_zone: "Europe/Paris"
          line :l1, company: :c1
        end
        line_provider :other do
          company :c2, registration_number: "1", time_zone: "Europe/Paris"
          line :l2, company: :c2
        end

        route line: :l1 do
          vehicle_journey
        end
        route line: :l2 do
          vehicle_journey
        end
      end
    end

    let(:first_company) {context.company(:c1)}
    let(:second_company) {context.company(:c2)}

    it "should use companies objectid when their registration_number is not unique" do
      expect(export.target.agencies.map(&:id)).to match_array([first_company.objectid, second_company.objectid])
    end

    context "when several companies are associated to referent" do
      let!(:context) do
        Chouette.create do
          line_provider :other do
            company :referent, registration_number: "1", time_zone: "Eastern Time (US & Canada)", is_referent: true
            line :l0, company: :referent
          end

          line_provider :first do
            company :c1, registration_number: "1", time_zone: "Europe/Paris", referent: :referent
            line :l1, company: :c1
          end

          line_provider :second do
            company :c2, registration_number: "1", time_zone: "Europe/Paris", referent: :referent
            line :l2, company: :c2
          end

          line_provider :third do
            company :c3, registration_number: "1", time_zone: "Europe/Paris"
            line :l3, company: :c3
          end

          route line: :l0 do
            vehicle_journey
          end
          route line: :l1 do
            vehicle_journey
          end
          route line: :l2 do
            vehicle_journey
          end
          route line: :l3 do
            vehicle_journey
          end
        end
      end

      let(:third_company) {context.company(:c3)}
      let(:referent_company) {context.company(:referent)}

      it "should not export several times the same Company Referent" do
        expect(export.target.agencies.map(&:id)).to match_array([referent_company.objectid, third_company.objectid])
      end
    end

    xdescribe "#default_company" do
      let!(:context) do
        Chouette.create do
          line_provider :first do
            company :c1, name: 'C1', time_zone: "Europe/Paris"
            company :c2, name: 'C2', time_zone: "Europe/Paris"

            line :l1, company: :c1
            line :l2, company: :c1

            line :l3, company: :c2
          end

          route line: :l1 do
            vehicle_journey
          end

          route line: :l2 do
            vehicle_journey
          end

          route line: :l3 do
            vehicle_journey
          end
        end
      end

      let(:expected_default_company) { context.company(:c1) }

      it "Should compute default company" do
        expect(part.default_company).to eq(expected_default_company)
        expect(index.default_company).to eq(expected_default_company)
      end
    end
  end

  describe Export::Gtfs::Companies::Decorator do
    let(:context) do
      Chouette.create do
        line_provider do
          company :company, fare_url: 'test.enroute.mobi'
        end
      end
    end
    let(:company) { context.company(:company) }
    let(:decorator) { described_class.new company }

    subject { decorator.agency_attributes[:fare_url] }

    it { is_expected.to eq('test.enroute.mobi') }
  end

  describe 'VehicleJourneyCompany Part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:index) { export.index }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup, referential: context.referential }

    let(:part) do
      Export::Gtfs::VehicleJourneyCompany.new export
    end

    let(:context) do
      Chouette.create do
        line_provider do
          company :first, name: 'dummy1'
          company :second, name: 'dummy2'
        end

        vehicle_journey :first, objectid: 'objectid1', company: :first
        vehicle_journey :second, objectid: 'objectid2', company: :second
      end
    end

    let(:first_company) { context.company(:first) }
    let(:second_company) { context.company(:second) }
    let(:first_vehicle_journey) { context.vehicle_journey(:first) }
    let(:second_vehicle_journey) { context.vehicle_journey(:second) }
    let(:line) { first_vehicle_journey.line }

    before do
      part.index.register_trip_id(first_vehicle_journey, 'trip_1')
      part.index.register_trip_id(second_vehicle_journey, 'trip_2')

      context.referential.switch

      line.update(company: second_company)
    end

    subject { export.target.attributions.map(&:trip_id) }

    it "should export attribution of the first vehicle_journey - company" do
      part.export!

      is_expected.to include('trip_1')
    end

    it "should not export attribution of the second vehicle_journey - company" do
      part.export!

      is_expected.not_to include(second_vehicle_journey.objectid)
    end
  end

  describe 'Contract Part' do
    let(:export_scope) { Export::Scope::All.new referential }
    let(:export) do
      Export::Gtfs.new(
        export_scope: export_scope,
        workbench: workbench,
        workgroup: workgroup,
        referential: referential
      )
    end

    let(:referential) { context.referential }
    let(:workbench) { context.workbench }
    let(:workgroup) { context.workgroup }

    let(:part) do
      Export::Gtfs::Contract.new export
    end

    let(:context) do
      Chouette.create do
        line_provider do
          company :first, name: 'first dummy'
          company :second, name: 'second dummy'
        end

        vehicle_journey :first, objectid: 'objectid1', company: :first
        vehicle_journey :second, objectid: 'objectid2', company: :second
      end
    end

    let(:first_company) { context.company(:first) }
    let(:first_vehicle_journey) { context.vehicle_journey(:first) }
    let(:line) { first_vehicle_journey.line }

    subject { export.target.attributions }

    before do
      referential.switch
      export.index.register_route_id(line, 'route_id')
      first_company.contracts.create(name: first_company.name, company: first_company, line_ids: [line.id], workbench: context.workbench)
    end

    subject { export.target.attributions }

    let(:expected_attributes) do
      {
        organization_name: 'first dummy',
        route_id: 'route_id',
        is_producer: 1
      }
    end

    it "should export attribution of the first company" do
      part.export!

      is_expected.to contain_exactly(an_object_having_attributes(expected_attributes))
    end

    describe Export::Gtfs::Contract::Decorator do
      subject(:decorator) { described_class.new contract }

      let(:contract) {  Contract.new }

      describe '#attributions' do
        subject { decorator.attributions }

        context 'when Contract is associated to a Line outside the export scope' do
          let(:included_line) { Chouette::Line.new registration_number: 'included' }
          let(:excluded_line) { Chouette::Line.new registration_number: 'excluded' }

          before do
            allow(contract).to receive(:lines).and_return([included_line, excluded_line])
          end

          before do
            route_id_for = -> (line) { line.registration_number unless line == excluded_line }
            allow(decorator).to receive(:route_id).and_invoke(route_id_for)
          end

          it { is_expected.to match_array(an_object_having_attributes(route_id: 'included')) }
        end
      end
    end
  end

  describe "TimeTable Decorator" do
    context "with a nil date_range" do
      context 'with one period' do
        let(:context) do
          Chouette::Factory.create do
            time_table dates_excluded: Time.zone.today, dates_included: Time.zone.tomorrow
          end
        end

        let(:time_table) { context.time_table }
        let(:decorator) { Export::Gtfs::TimeTables::TimeTableDecorator.new time_table }

        it "should return one period" do
          expect(decorator.periods.length).to eq 1
        end

        it "should return two dates" do
          expect(decorator.dates.length).to eq 2
        end

        it "should return a calendar with default service_id" do
          c = decorator.calendars
          expect(c.count).to eq 1
          expect(c.first[:service_id]).to eq decorator.default_service_id
        end

        it "should return calendar_dates with correct service_id" do
          cd = decorator.calendar_dates
          expect(cd.count).to eq 2
          cd.each do |date|
            expect(date[:service_id]).to eq decorator.default_service_id
          end
        end
      end

      context 'with multiple periods' do
        let(:context) do
          Chouette::Factory.create do
            time_table periods: [ Time.zone.today..Time.zone.today+1, Time.zone.today+3..Time.zone.today+4 ]
          end
        end

        let(:time_table) { context.time_table }
        let(:decorator) { Export::Gtfs::TimeTables::TimeTableDecorator.new time_table }

        it "should return two periods" do
          expect(decorator.periods.length).to eq 2
        end

        it "should return calendars with correct service_id" do
          c = decorator.calendars
          expect(c.count).to eq 2
          expect(c.first[:service_id]).to eq decorator.default_service_id
          expect(c.last[:service_id]).to eq time_table.periods.last.id
        end
      end
    end

    context "with a non nil date_range" do
      let(:context) do
        Chouette::Factory.create do
          time_table dates_excluded: Time.zone.today+1,
                     dates_included: 1.month.from_now.to_date,
                     periods: [ Time.zone.today..Time.zone.today+2, Time.zone.today+5..Time.zone.today+6 ]
        end
      end

      let(:time_table) { context.time_table }
      let(:decorator) { Export::Gtfs::TimeTables::TimeTableDecorator.new time_table, Time.zone.tomorrow..Time.zone.tomorrow+1 }

      it "should return one period" do
        expect(decorator.periods.length).to eq 1
      end

      it "should return one date" do
        expect(decorator.dates.length).to eq 1
      end
    end
  end

  describe 'JourneyPatternDistances part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup }

    let(:part) do
      Export::Gtfs::JourneyPatternDistances.new export
    end

    let(:context) do
      Chouette.create do
        stop_area :departure
        stop_area :second
        stop_area :third
        stop_area :arrival

        route with_stops: false do
          stop_point :departure
          stop_point :second
          stop_point :third
          stop_point :arrival

          vehicle_journey
        end

        journey_pattern :journey_pattern_without_costs
        journey_pattern :journey_pattern_with_empty_costs_hash
      end
    end

    let(:vehicle_journey_at_stops) { referential.vehicle_journey_at_stops }
    let(:journey_pattern) { context.vehicle_journey.journey_pattern }
    let(:journey_pattern_without_costs) { context.journey_pattern(:journey_pattern_without_costs) }
    let(:journey_pattern_with_empty_costs_hash) { context.journey_pattern(:journey_pattern_with_empty_costs_hash) }

    let(:departure_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=0').first }
    let(:second_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=1').first }
    let(:third_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=2').first }
    let(:arrival_at_stop) { vehicle_journey_at_stops.joins(:stop_point).where('stop_points.position=3').first }

    let(:departure_stop_point) { departure_at_stop.stop_point }
    let(:second_stop_point) { second_at_stop.stop_point }
    let(:third_stop_point) { third_at_stop.stop_point }
    let(:arrival_stop_point) { arrival_at_stop.stop_point }

    let(:departure_stop) { departure_at_stop.stop_point.stop_area }
    let(:second_stop) { second_at_stop.stop_point.stop_area }
    let(:third_stop) { third_at_stop.stop_point.stop_area }
    let(:arrival_stop) { arrival_at_stop.stop_point.stop_area }

    before do
      context.referential.switch

      journey_pattern.update costs: {
        "#{departure_stop.id}-#{second_stop.id}" => { 'distance' => 1 },
        "#{second_stop.id}-#{third_stop.id}" => { 'distance' => 2 },
        "#{third_stop.id}-#{arrival_stop.id}" => { 'distance' => 3 }
      }

      journey_pattern_without_costs.update costs: nil
    end

    def distance(journey_pattern, stop_point)
      export.index.journey_pattern_distance(journey_pattern.id, stop_point.id)
    end

    subject { part.export! }

    it { expect(part.journey_patterns).not_to include(journey_pattern_without_costs) }

    it { expect(part.journey_patterns).not_to include(journey_pattern_with_empty_costs_hash) }

    it { expect(part.journey_patterns).to include(journey_pattern) }

    context 'for departure stop_point' do
      it { expect { subject }.to change { distance journey_pattern, departure_stop_point }.from(nil).to(0) }
    end

    context 'for second stop_point' do
      it { expect { subject }.to change { distance journey_pattern, second_stop_point }.from(nil).to(1) }
    end

    context 'for third stop_point' do
      it { expect { subject }.to change { distance journey_pattern, third_stop_point }.from(nil).to(3) }
    end

    context 'for arrival stop_point' do
      it { expect { subject }.to change { distance journey_pattern, arrival_stop_point }.from(nil).to(6) }
    end
  end

  describe "VehicleJourneyAtStop Part" do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup }

    let(:part) do
      Export::Gtfs::VehicleJourneyAtStops.new export
    end

    let(:context) do
      Chouette.create do
        stop_area :non_commercial, kind: 'non_commercial', area_type: 'deposit'

        stop_area :referent, kind: 'non_commercial', area_type: 'deposit', is_referent: true
        stop_area :with_referent_non_commercial, referent: :referent

        route with_stops: false do
          stop_point :departure
          stop_point :stop_non_commercial, stop_area: :non_commercial
          stop_point :stop_with_referent_non_commercial, stop_area: :with_referent_non_commercial
          stop_point :arrival

          vehicle_journey
        end
      end
    end

    before do
      context.referential.switch
    end

    context "when prefer_referent_stop_area is true" do
      before { export.options["prefer_referent_stop_area"] = true }

      it "ignore Vehicle Journey At Stops associated to a non commercial Referent Stop Area" do
        expect(part.vehicle_journey_at_stops.length).to eq(2)
      end
    end

    context "when prefer_referent_stop_area is false" do
      before { export.options["prefer_referent_stop_area"] = false }

      it "ignore Vehicle Journey At Stops associated to a non commercial Stop Area" do
        expect(part.vehicle_journey_at_stops.length).to eq(3)
      end
    end
  end

  describe "VehicleJourneyAtStop Decorator" do

    let(:vehicle_journey) { Chouette::VehicleJourney.new }
    let(:vehicle_journey_at_stop) { Chouette::VehicleJourneyAtStop.new(vehicle_journey: vehicle_journey) }
    let(:vjas_raw_hash) {
      {
        departure_time: vehicle_journey_at_stop.departure_time,
        arrival_time: vehicle_journey_at_stop.arrival_time,
        departure_day_offset: vehicle_journey_at_stop.departure_day_offset,
        arrival_day_offset: vehicle_journey_at_stop.arrival_day_offset,
        vehicle_journey_id: vehicle_journey_at_stop.vehicle_journey_id,
        stop_area_id: vehicle_journey_at_stop.stop_area_id,
        parent_stop_area_id: vehicle_journey_at_stop.stop_point&.stop_area_id,
        position: vehicle_journey_at_stop.stop_point&.position,
        for_alighting: vehicle_journey_at_stop.stop_point&.for_alighting,
        for_boarding: vehicle_journey_at_stop.stop_point&.for_boarding,
      }.stringify_keys
    }

    let(:index) { double }
    let(:decorator) do
      Export::Gtfs::VehicleJourneyAtStops::Decorator.new vjas_raw_hash, index: index
    end

    let(:time_zone) { "Europe/Paris" }

    describe "time zone" do

      it "uses time zone associated with the VehicleJourney in the index" do
        vehicle_journey_at_stop.vehicle_journey_id = 42
        expect(index).to receive(:vehicle_journey_time_zone).
                           with(vehicle_journey_at_stop.vehicle_journey_id).
                           and_return(time_zone)
        expect(decorator.time_zone).to be(time_zone)
      end

      it "returns nil if the VehicleJourney isn't associated to a time zone" do
        vehicle_journey_at_stop.vehicle_journey_id = 42
        expect(index).to receive(:vehicle_journey_time_zone).
                           with(vehicle_journey_at_stop.vehicle_journey_id).
                           and_return(nil)
        expect(decorator.time_zone).to be(nil)
      end

    end

    %w{arrival departure}.each do |state|
      describe "#{state}_time_of_day" do

        subject { decorator.send "#{state}_time_of_day" }

        context "when #{state}_time is nil" do
          before { allow(decorator).to receive("#{state}_time").and_return(nil) }

          it { is_expected.to be_nil }
        end

        context "when #{state}_time is defined" do
          it "uses #{state}_time to create a TimeOfDay" do
            allow(decorator).to receive("#{state}_time").and_return("14:00")
            is_expected.to eq(TimeOfDay.new(14))
          end

          it "uses #{state}_day_offset to create TimeOfDay" do
            allow(decorator).to receive("#{state}_time").and_return("14:00")
            allow(decorator).to receive("#{state}_day_offset").and_return(1)

            is_expected.to eq(TimeOfDay.new(14, day_offset: 1))
          end
        end

      end

      describe "#{state}_local_time_of_day" do

        subject { decorator.send "#{state}_local_time_of_day" }

        context "when #{state}_time is nil" do
          before { allow(decorator).to receive("#{state}_time").and_return(nil) }
          it { is_expected.to be_nil }
        end

        context "when #{state}_time_of_day is nil" do
          before { allow(decorator).to receive("#{state}_time_of_day").and_return(nil) }
          it { is_expected.to be_nil }
        end

        context "when #{state}_time_of_day is defined" do

          let(:time_of_day) { TimeOfDay.new(14) }
          before { allow(decorator).to receive("#{state}_time_of_day").and_return(time_of_day) }

          context "when time_zone is defined" do

            let(:time_zone) { "Europe/Paris" }
            before { allow(decorator).to receive(:time_zone).and_return(time_zone) }

            it "returns #{state}_time_of_day with time_zone offset" do
              is_expected.to eq(time_of_day.with_utc_offset(1.hour))
            end
          end

          context "when time_zone is not defined" do
            before { allow(decorator).to receive(:time_zone).and_return(nil) }

            it "returns #{state}_time_of_day unchanged" do
              is_expected.to eq(time_of_day)
            end
          end

        end

      end

      describe "stop_time_#{state}_time" do

        subject { decorator.send "stop_time_#{state}_time" }

        context "when #{state}_local_time_of_day is nil" do
          before { allow(decorator).to receive("#{state}_time_of_day").and_return(nil) }
          it { is_expected.to be_nil }
        end

        context "when #{state}_local_time_of_day is defined" do

          let(:time_of_day) { TimeOfDay.new(14) }
          before { allow(decorator).to receive("#{state}_local_time_of_day").and_return(time_of_day) }

          it "returns a GTFS::Time string representation based on #{state}_local_time_of_day value" do
            is_expected.to eq("14:00:00")
          end

        end

      end

    end

    describe "stop_area_id" do

      let(:stop_point) { double stop_area_id: 42, position: 21, for_alighting:'', for_boarding:'' }

      context "when VehicleJourneyAtStop defines a specific stop" do

        before { vehicle_journey_at_stop.stop_area_id = 42 }

        it "uses the VehicleJourneyAtStop#stop_area_id" do
          expect(decorator.stop_area_id).to eq(vehicle_journey_at_stop.stop_area_id)
        end

      end

      it "uses the Stop Point stop_area_id" do
        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.stop_area_id).to eq(stop_point.stop_area_id)
      end

    end

    describe "position" do

      let(:stop_point) { double stop_area_id: 21, position: 42, for_alighting:'', for_boarding:'' }

      it "uses the Stop Point position" do
        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.position).to eq(stop_point.position)
      end

    end

    describe "drop_off_type" do

      let(:stop_point) { double stop_area_id: 21, position: 42, for_boarding:''}

      it 'return the correct value when for_alighting is forbidden' do
        allow(stop_point).to receive(:for_alighting).and_return('forbidden')

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.drop_off_type).to eq(1)
      end

      it 'return the correct value when for_alighting is not forbidden' do
        allow(stop_point).to receive(:for_alighting).and_return(nil)

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.drop_off_type).to eq(nil)
      end

    end

    describe "pickup_type" do

      let(:stop_point) { double stop_area_id: 21, position: 42, for_alighting:''}

      it 'return the correct value when for_boarding is forbidden' do
        allow(stop_point).to receive(:for_boarding).and_return('forbidden')

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.pickup_type).to eq(1)
      end

      it 'return the correct value when for_boarding is not forbidden' do
        allow(index).to receive(:pickup_type).with(vehicle_journey_at_stop.vehicle_journey.id).and_return(nil)
        allow(stop_point).to receive(:for_boarding).and_return(nil)

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.pickup_type).to eq(0)
      end

      it 'return the correct value when for_boarding is not forbidden and vehicle_journey is registered in the index' do
        allow(index).to receive(:pickup_type).with(vehicle_journey_at_stop.vehicle_journey.id).and_return(true)

        allow(stop_point).to receive(:for_boarding).and_return(nil)

        expect(vehicle_journey_at_stop).to receive(:stop_point).at_least(:once).and_return(stop_point)
        expect(decorator.pickup_type).to eq(2)
      end

    end


    describe "stop_time_stop_id" do

      it "uses stop_id associated to the stop_area_id in the index" do
        allow(decorator).to receive(:stop_area_id).and_return(42)
        expect(index).to receive(:stop_id).
                           with(decorator.stop_area_id).
                           and_return("test")

        expect(decorator.stop_time_stop_id).to eq("test")
      end

    end

    describe "stop_time attributes" do

      before do
        allow(index).to receive_messages(pickup_type: 0)
        allow(decorator).to receive_messages(time_zone: nil, position: 42, stop_time_stop_id: "test")
        vehicle_journey_at_stop.departure_time =
          vehicle_journey_at_stop.arrival_time = Time.parse("23:00")
      end

      %i{departure_time arrival_time stop_id}.each do |stop_time_attribute|
        attribute = "stop_time_#{stop_time_attribute}".to_sym
        it "uses #{attribute} method to fill associated attribute (#{stop_time_attribute})" do
          allow(decorator).to receive(attribute).and_return("test")
          stop_time_attribute = attribute.to_s.gsub(/^stop_time_/,'').to_sym
          expect(decorator.stop_time_attributes[stop_time_attribute]).to eq(decorator.send(attribute))
        end
      end

      it "uses position to fill the same stop_sequence attribute" do
        allow(decorator).to receive(:position).and_return(42)
        expect(decorator.stop_time_attributes[:stop_sequence]).to eq(decorator.position)
      end

    end
  end

  describe 'VehicleJourneys Part' do

    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:index) { export.index }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup }

    let(:part) do
      Export::Gtfs::VehicleJourneys.new export
    end

    let(:context) do
      Chouette.create do
        time_table :default
        vehicle_journey time_tables: [:default]
        vehicle_journey time_tables: [:default]
      end
    end

    let(:time_table) { context.time_table(:default) }
    let(:vehicle_journeys) { context.vehicle_journeys }

    before do
      context.referential.switch
      index.register_services time_table, [Export::Gtfs::Service.new(time_table.objectid)]
    end

    it "registers the GTFS Trip identifiers used for each VehicleJourney" do
      part.export!
      vehicle_journeys.each do |vehicle_journey|
        expect(index.trip_ids(vehicle_journey.id)).to eq([vehicle_journey.objectid])
      end
    end

    context "when the Line has flexible service" do
      it "registers the GTFS pickup_type according to the Line" do
        vehicle_journey = vehicle_journeys.first
        vehicle_journey.line.update flexible_line_type: :other

        part.export!

        expect(index.pickup_type(vehicle_journey.id)).to be_truthy
      end
    end

  end

  describe Export::Gtfs::VehicleJourneys::ServiceFinder do
    subject(:finder) { described_class.new services }
    let(:services) { [] }

    describe '#single' do
      subject { finder.single }

      let(:service) { Export::Gtfs::Service.new('test') }
      let(:services) { [service] }

      context 'when a single Service is present' do
        it 'returns this Service' do
          is_expected.to eq(service)
        end
      end

      context 'when several Services are present' do
        let(:services) { 3.times.map { double } }
        it { is_expected.to be_nil }
      end
    end

    context 'when today is 2030-01-15' do
      before { allow(finder).to receive(:today).and_return(today) }
      let(:today) { Date.parse '2030-01-15' }

      describe '#current' do
        subject { finder.current }

        context 'when no service is present' do
          it { is_expected.to be_nil }
        end

        context 'when a Service validity period includes today' do
          let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-10..2030-01-20')) }
          let(:services) { [service] }

          it { is_expected.to eq(service) }
        end

        context 'when no Service validity period includes today' do
          let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-20..2030-01-30')) }
          let(:services) { [service] }

          it { is_expected.to be_nil }
        end

        context 'when several services includes today in their validity periods' do
          let(:first) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-10..2030-01-20')) }
          let(:second) { Export::Gtfs::Service.new('second', validity_period: Period.parse('2030-01-10..2030-01-20')) }
          let(:services) { [first, second] }

          it 'returns the first one' do
            is_expected.to eq(first)
          end
        end
      end

      describe '#nexts' do
        subject { finder.nexts }

        context 'when no service is present' do
          it { is_expected.to be_empty }
        end

        context 'when a Service is before today' do
          let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-01..2030-01-10')) }
          let(:services) { [service] }

          it { is_expected.to_not include(service) }
        end

        context 'when a Service starts before today' do
          let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-01..2030-01-30')) }
          let(:services) { [service] }

          it { is_expected.to_not include(service) }
        end

        context 'when a Service starts after today' do
          let(:service) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-20..2030-01-30')) }
          let(:services) { [service] }

          it { is_expected.to include(service) }
        end

        context 'when several Service start after today' do
          let(:services) do
            3.times.map do |n|
              Export::Gtfs::Service.new("test-#{n}", validity_period: Period.parse('2030-01-20..2030-01-30'))
            end
          end
          it { is_expected.to match_array(services) }
        end
      end

      describe '#next' do
        subject { finder.next }

        before { allow(finder).to receive(:nexts).and_return(nexts) }
        let(:nexts) { [] }

        context 'when no next service is found' do
          it { is_expected.to be_nil }
        end

        context 'when several next services are found' do
          let(:first) { Export::Gtfs::Service.new('test', validity_period: Period.parse('2030-01-20..2030-01-30')) }
          let(:second) { Export::Gtfs::Service.new('second', validity_period: Period.parse('2030-01-21..2030-01-30')) }
          let(:nexts) { [first, second] }

          it 'returns the Service with the nearest start' do
            is_expected.to eq(first)
          end
        end
      end

      describe '#preferred' do
        subject { finder.preferred }

        context 'when single is defined' do
          before { allow(finder).to receive(:single).and_return(double('single')) }
          it { is_expected.to eq(finder.single) }
        end

        context 'when single is nil' do
          before { allow(finder).to receive(:single).and_return(nil) }

          context 'when current is defined' do
            before { allow(finder).to receive(:current).and_return(double('current')) }
            it { is_expected.to eq(finder.current) }
          end

          context 'when current is nil' do
            before { allow(finder).to receive(:current).and_return(nil) }

            context 'when next is defined' do
              before { allow(finder).to receive(:next).and_return(double('next')) }
              it { is_expected.to eq(finder.next) }
            end

            context 'when next is nil' do
              before { allow(finder).to receive(:next).and_return(nil) }
              it { is_expected.to be_nil }
            end
          end
        end
      end
    end
  end

  describe 'VehicleJourney Decorator' do

    let(:vehicle_journey) { Chouette::VehicleJourney.new }
    let(:index) { Export::Gtfs::Index.new }
    let(:resource_code_space) { double }
    let(:line ) { Chouette::Line.new(id: rand(100)) }
    let(:accessibility_assessment ) { AccessibilityAssessment.new(id: rand(100)) }


    let(:decorator) do
      Export::Gtfs::VehicleJourneys::Decorator.new vehicle_journey, index: index, code_provider: resource_code_space
    end

    describe '#route_id' do

      subject { decorator.route_id }

      let(:indexed_route_id) { double 'GTFS route_id associated to the VehicleJourney line' }

      before do
        vehicle_journey.route = Chouette::Route.new(line_id: line.id)
        index.register_route_id line, indexed_route_id
      end

      it { is_expected.to be(indexed_route_id) }

    end

    describe '#trip_id' do
      subject { decorator.trip_id(service) }

      let(:service) { Export::Gtfs::Service.new('service_id') }
      let(:base_trip_id) { 'base_trip_id' }

      before do
        allow(decorator).to receive(:base_trip_id).and_return(base_trip_id)
      end

      context "when the target service isn't the preferred one" do
        before { allow(decorator).to receive(:preferred_service).and_return(nil) }

        it 'uses the base trip id suffixed with service id' do
          is_expected.to eq('base_trip_id-service_id')
        end
      end

      context 'when the target service is the preferred one' do
        before { allow(decorator).to receive(:preferred_service).and_return(service) }

        it 'uses the raw base trip id' do
          is_expected.to eq(base_trip_id)
        end
      end

      describe '#trip_attributes' do
        subject { decorator.trip_attributes(service) }

        it 'uses route_id as attribute' do
          allow(decorator).to receive(:route_id).and_return(rand(100))
          is_expected.to include(route_id: decorator.route_id)
        end

        it 'uses the given Service id as attribute' do
          is_expected.to include(service_id: service.id)
        end

        it 'uses trip_id (with given service_id) as id attribute' do
          allow(decorator).to receive(:trip_id).with(service).and_return('trip_id')
          is_expected.to include(id: 'trip_id')
        end

        it 'uses published_journey_name as short_name attribute' do
          vehicle_journey.published_journey_name = 'published_journey_name'
          is_expected.to include(short_name: vehicle_journey.published_journey_name)
        end

        it 'uses direction_id as attribute' do
          allow(decorator).to receive(:direction_id).and_return(0)
          is_expected.to include(direction_id: decorator.direction_id)
        end

        it 'uses shape_id as attribute' do
          allow(decorator).to receive(:shape_id).and_return(42)
          is_expected.to include(shape_id: decorator.gtfs_shape_id)
        end
      end
    end

    describe '#gtfs_code' do

      subject { decorator.gtfs_code }
      before { allow(resource_code_space).to receive(:unique_code).and_return(code) }

      describe 'when the VehicleJourney has no code' do
        let(:code) { nil }
        it { is_expected.to be_nil }
      end

      describe 'when the VehicleJourney has an unique code' do
        let(:code) { 'unique_code' }
        it { is_expected.to eq(code) }
      end

    end

    describe '#base_trip_id' do

      subject { decorator.base_trip_id }

      before { vehicle_journey.objectid = 'test' }

      context 'when gtfs_code is nil' do

        before { allow(decorator).to receive(:gtfs_code).and_return(nil) }

        it "returns VehicleJourney objectid" do
          is_expected.to eq(vehicle_journey.objectid)
        end

      end

      context 'when gtfs_code has a value' do

        before { allow(decorator).to receive(:gtfs_code).and_return('test') }

        it "returns this gtfs_code" do
          is_expected.to eq(decorator.gtfs_code)
        end

      end

    end

    describe '#wheelchair_accessible' do
      subject { decorator.gtfs_wheelchair_accessibility }

      before do
        accessibility_assessment.wheelchair_accessibility = wheelchair_accessibility
        allow(vehicle_journey).to receive(:accessibility_assessment).and_return(accessibility_assessment)
      end

      context "when wheelchair accessibility is 'unknown'" do
        let(:wheelchair_accessibility) { 'unknown' }

        it { is_expected.to eq '0' }
      end

      context "when wheelchair accessibility is 'yes'" do
        let(:wheelchair_accessibility) { 'yes' }

        it { is_expected.to eq '1' }
      end

      context "when wheelchair accessibility is 'no'" do
        let(:wheelchair_accessibility) { 'no' }

        it { is_expected.to eq '2' }
      end
    end

    describe '#bikes_allowed' do
      subject { decorator.gtfs_bikes_allowed }

      let(:service_facility_set) { ServiceFacilitySet.new(associated_services: associated_services) }
      let(:associated_services) { [] }

      let(:service_facility_sets) { [ service_facility_set ] }

      before do
        allow(vehicle_journey).to receive(:service_facility_sets).and_return(service_facility_sets)
      end

      context "when associated_services is 'luggage_carriage/cycles_allowed'" do
        let(:associated_services) { ['luggage_carriage/cycles_allowed'] }

        it { is_expected.to eq '1' }
      end

      context "when associated services is 'luggage_carriage/no_cycles'" do
        let(:associated_services) { ['luggage_carriage/no_cycles'] }

        it { is_expected.to eq '2' }
      end

      context "when associated services contains both 'luggage_carriage/cycles_allowed' and 'luggage_carriage/no_cycles'" do
        let(:associated_services) { ['luggage_carriage/cycles_allowed'] }

        before do
          service_facility_sets << ServiceFacilitySet.new(associated_services: ['luggage_carriage/no_cycles'])
        end

        it { is_expected.to eq '0' }
      end
    end

    describe '#services' do
      subject { decorator.services }

      def services(*identifiers)
        identifiers.flatten!
        identifiers.map do |identifier|
          Export::Gtfs::Service.new identifier
        end.to_set
      end

      before do
        decorator.index.register_services double(id: 1), services(%w[a b c])
        decorator.index.register_services double(id: 2), services(%w[d e f])

        allow(decorator).to receive(:time_table_ids).and_return([1, 2])
      end

      it 'returns all the GTFS service identifiers associated to Vehicle Journey TimeTable identifiers' do
        is_expected.to match_array(services(%w[a b c d e f]))
      end
    end

    describe '#direction_id' do

      subject { decorator.direction_id }

      before do
        vehicle_journey.route = Chouette::Route.new wayback: wayback
      end

      context "when route wayback is outbound" do
        let(:wayback) { Chouette::Route.outbound }
        it { is_expected.to eq(0) }
      end

      context "when route wayback is inbound" do
        let(:wayback) { Chouette::Route.inbound }
        it { is_expected.to eq(1) }
      end

    end

    describe '#shape_id' do

      subject { decorator.gtfs_shape_id }

      context "when a Shape is associated to the Journey Pattern" do
        let(:indexed_shape_id) { double 'GTFS shape_id associated to the JourneyPattern Shape' }

        before do
          shape = Shape.new id: 42
          vehicle_journey.journey_pattern = Chouette::JourneyPattern.new(shape_id: shape.id)
          index.register_shape_id shape, indexed_shape_id
        end

        it { is_expected.to be(indexed_shape_id) }
      end

      context "when no Shape is associated to the Journey Pattern" do
        before do
          vehicle_journey.journey_pattern = Chouette::JourneyPattern.new
        end

        it { is_expected.to be_nil }
      end

    end

    describe 'gtfs_headsign' do
      subject { decorator.gtfs_headsign }

      context 'when JourneyPattern published_name is "dummy"' do
        before { allow(decorator).to receive(:journey_pattern).and_return(double(published_name: 'dummy')) }
        it { is_expected.to eq('dummy') }
      end
    end
  end

  describe 'Shapes Part' do
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup }

    let(:part) do
      Export::Gtfs::Shapes.new export
    end

    let(:context) do
      Chouette.create do
        shape
        shape

        referential
      end
    end

    let(:shapes) { context.shapes }

    it 'creates a GTFS Shape for each Shape' do
      part.export!

      shape_ids = export.target.shape_points.map(&:shape_id).uniq
      expect(shape_ids.count).to eq(shapes.count)
    end

    it 'creates a GTFS ShapePoint for each Shape geometry point' do
      part.export!

      gtfs_shape_points = export.target.shape_points
      shape_points = shapes.map { |shape| shape.geometry.points }.flatten

      expect(gtfs_shape_points.count).to eq(shape_points.count)
    end

    it 'registers the used GTFS Shape id for each Shape' do
      part.export!

      shapes.each do |shape|
        expect(export.index.shape_id(shape.id)).to be_present
      end
    end

    describe 'Decorator' do
      let(:shape) { Shape.new }
      let(:decorator) { Export::Gtfs::Shapes::Decorator.new shape, code_provider: code_provider }
      let(:code_provider) { double }

      describe '#gtfs_code' do
        subject { decorator.gtfs_code }

        it 'uses unique code from code provider' do
          expect(code_provider).to receive(:unique_code).with(decorator).and_return(unique_code = 'unique_code')
          is_expected.to eq(unique_code)
        end
      end

      describe '#gtfs_id' do
        subject { decorator.gtfs_id }

        context 'when the GTFS code is nil' do
          before { allow(decorator).to receive(:gtfs_code).and_return(nil) }
          it 'is the Shape uuid' do
            is_expected.to eq(shape.uuid)
          end
        end

        context 'when the GTFS code is defined' do
          before { allow(decorator).to receive(:gtfs_code).and_return('gtfs_code') }
          it 'is the GTFS code' do
            is_expected.to eq(decorator.gtfs_code)
          end
        end
      end

      describe '#gtfs_shape_points' do
        before { shape.geometry = 'LINESTRING(2.2945 48.8584,2.295 48.859)' }

        subject { decorator.gtfs_shape_points }

        it 'includes a GTFS::ShapePoint for each geometry point' do
          is_expected.to match_array([
            have_attributes(pt_lat: 48.8584, pt_lon: 2.2945),
            have_attributes(pt_lat: 48.859, pt_lon: 2.295)
          ])
        end
      end
    end
  end

  describe 'FeedInfo' do
    describe Export::Gtfs::FeedInfo::Decorator do
      let(:decorator) { Export::Gtfs::FeedInfo::Decorator.new(company: company, validity_period: validity_period) }
      let(:company) { Chouette::Company.new }
      let(:validity_period) { Period.from(:today) }

      describe '#start_date' do
        subject { decorator.start_date }

        context 'when Referential validity period starts on 2030-01-01' do
          let(:validity_period) { Period.from('2030-01-01') }

          it { is_expected.to eq(Date.parse('2030-01-01')) }
        end
      end

      describe '#end_date' do
        subject { decorator.end_date }

        context 'when Referential validity period starts on 2030-12-31' do
          let(:validity_period) { Period.from(:today).until('2030-12-31') }

          it { is_expected.to eq(Date.parse('2030-12-31')) }
        end
      end

      describe '#gtfs_start_date' do
        subject { decorator.gtfs_start_date }

        context 'when start date is 2030-01-15' do
          let(:validity_period) { Period.from('2030-01-15') }

          it { is_expected.to eq('20300115') }
        end
      end

      describe '#gtfs_end_date' do
        subject { decorator.gtfs_end_date }

        context 'when end date is 2030-01-15' do
          let(:validity_period) { Period.from(:today).until('2030-01-15') }

          it { is_expected.to eq('20300115') }
        end
      end

      describe '#publisher_name' do
        subject { decorator.publisher_name }

        context 'when company name is "dummy"' do
          before { company.name = 'dummy' }

          it { is_expected.to eq(company.name) }
        end

        context 'no company is not available' do
          let(:company) { nil }

          it { is_expected.to be_nil }
        end
      end

      describe '#publisher_url' do
        subject { decorator.publisher_url }

        context 'when company default contact url is "http://example.com"' do
          before { company.default_contact_url = 'http://example.com' }

          it { is_expected.to eq(company.default_contact_url) }
        end

        context 'no company is not available' do
          let(:company) { nil }

          it { is_expected.to be_nil }
        end
      end

      describe '#language' do
        subject { decorator.language }

        context 'when company default language is "en"' do
          before { company.default_language = 'en' }

          it { is_expected.to eq(company.default_language) }
        end

        context 'no company is not available' do
          let(:company) { nil }

          it { is_expected.to eq('fr') }
        end

        context 'when company default language is not defined' do
          before { company.default_language = '' }

          it { is_expected.to eq('fr') }
        end
      end
    end
  end

  describe 'CodeSpaces' do

    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:code_space) { context.workgroup.code_spaces.default }
    let(:code_spaces) { Export::Gtfs::CodeSpaces.new code_space, scope: export_scope }

    before { context.referential.switch }

    describe "for Shapes" do

      let(:context) do
        Chouette.create do
          shape :first
          shape :second

          referential
        end
      end

      let(:resource) { code_spaces.shapes }

      let(:shape) { context.shape :first }
      let(:other_shape) { context.shape :second }

      describe '#unique_code' do
        subject { resource.unique_code shape }

        context 'when the Shape is several codes' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            shape.codes.create! code_space: code_space, value: '2'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape is no code' do
          before { shape.codes.delete_all }

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a code already used by another Vehicle Journey' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            other_shape.codes.create! code_space: code_space, value: '1'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a unique code' do
          let(:unique_code_value) { 'unique' }
          before do
            shape.codes.create! code_space: code_space, value: unique_code_value
          end

          it { is_expected.to eq(unique_code_value) }
        end

      end

    end

    describe "for Shapes" do

      let(:context) do
        Chouette.create do
          shape :first
          shape :second

          referential
        end
      end

      let(:resource) { code_spaces.shapes }

      let(:shape) { context.shape :first }
      let(:other_shape) { context.shape :second }

      describe '#unique_code' do
        subject { resource.unique_code shape }

        context 'when the Shape is several codes' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            shape.codes.create! code_space: code_space, value: '2'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape is no code' do
          before { shape.codes.delete_all }

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a code already used by another Shape' do
          before do
            shape.codes.create! code_space: code_space, value: '1'
            other_shape.codes.create! code_space: code_space, value: '1'
          end

          it { is_expected.to be_nil }
        end

        context 'when the Shape has a unique code' do
          let(:unique_code_value) { 'unique' }
          before do
            shape.codes.create! code_space: code_space, value: unique_code_value
          end

          it { is_expected.to eq(unique_code_value) }
        end

      end

    end


  end

  describe Export::Gtfs::Service do
    subject(:service) { Export::Gtfs::Service.new('test') }

    describe '==' do
      subject { service == other }

      context 'when the given Service has the same id' do
        let(:other) { Export::Gtfs::Service.new('test') }
        it { is_expected.to be_truthy }
      end

      context 'when the given Service has a different id' do
        let(:other) { Export::Gtfs::Service.new('other') }
        it { is_expected.to be_falsy }
      end

      context 'when the given Service is nil' do
        let(:other) { nil }
        it { is_expected.to be_falsy }
      end
    end

    describe '#extend_validity_period' do
      context 'when the Service has no validity period' do
        it 'sets to the validity period to the given period' do
          period = Period.parse('2030-01-01..2030-01-10')
          expect { service.extend_validity_period(period) }.to change(service, :validity_period).from(nil).to(period)
        end
      end

      context 'when the Service has the validity period "2030-01-10..2030-01-20"' do
        before { service.validity_period = Period.parse '2030-01-10..2030-01-20' }

        context 'when the period "2030-01-20..2030-01-30" is given' do
          let(:period) { Period.parse '2030-01-20..2030-01-30' }

          it do
            expect { service.extend_validity_period(period) }.to change(service, :validity_period)
              .to(Period.parse('2030-01-10..2030-01-30'))
          end
        end

        context 'when the date "2030-01-30" is given' do
          let(:date) { Date.parse '2030-01-30' }

          it do
            expect { service.extend_validity_period(date) }.to change(service, :validity_period)
              .to(Period.parse('2030-01-10..2030-01-30'))
          end
        end
      end
    end
  end

  describe '#worker_died' do

    it 'should set gtfs_export status to failed' do
      expect(gtfs_export.status).to eq("new")
      gtfs_export.worker_died
      expect(gtfs_export.status).to eq("failed")
    end
  end

  it "should create a default company and generate a message if the journey or its line doesn't have a company" do
    exported_referential.switch do
      exported_referential.lines.update_all company_id: nil
      line = exported_referential.lines.first

      stop_areas = stop_area_referential.stop_areas.order(Arel.sql('random()')).limit(2)
      route = FactoryBot.create :route, line: line, stop_areas: stop_areas, stop_points_count: 0
      journey_pattern = FactoryBot.create :journey_pattern, route: route, stop_points: route.stop_points.sample(3)
      FactoryBot.create :vehicle_journey, journey_pattern: journey_pattern, company: nil

      gtfs_export.export_scope = Export::Scope::All.new(exported_referential)

      tmp_dir = Dir.mktmpdir

      agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')
      GTFS::Target.open(agencies_zip_path) do |target|
        gtfs_export.export_companies_to target
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build agencies_zip_path, strict: false
      expect(source.agencies.length).to eq(1)
      agency = source.agencies.first
      expect(agency.id).to eq("chouette_default")
      expect(agency.timezone).to eq("Etc/UTC")

      # Test the line-company link
      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      GTFS::Target.open(lines_zip_path) do |target|
        expect { gtfs_export.export_lines_to target }.to change { Export::Message.count }.by(2)
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build lines_zip_path, strict: false
      route = source.routes.first
      expect(route.agency_id).to eq("chouette_default")
    end
  end

  describe 'When agency timezone is defined' do
    let(:context) do
      Chouette.create do
        line_provider :first do
          company :c1, time_zone: 'Europe/Paris'
          line :l1, company: :c1
        end

        stop_area :departure, time_zone: 'Europe/Athens'
        stop_area :second
        stop_area :arrival

        referential lines: [:l1] do
          time_table :default
          route line: :l1, stop_areas: [:departure, :second, :arrival] do
            vehicle_journey time_tables: [:default]
          end
        end
      end
    end

    let(:exported_referential) { context.referential }
    let(:vehicle_journey) { context.vehicle_journey }

    it "gtfs export stop times use agency timezone" do
      exported_referential.switch do
        gtfs_export.duration = nil
        gtfs_export.export_scope = Export::Scope::All.new(exported_referential)

        tmp_dir = Dir.mktmpdir
        gtfs_export.export_to_dir tmp_dir

        # The processed export files are re-imported through the GTFS gem
        stop_times_zip_path = File.join(tmp_dir, "#{gtfs_export.zip_file_name}.zip")
        source = GTFS::Source.build stop_times_zip_path, strict: false

        first_vehicle_journey_at_stop = vehicle_journey.vehicle_journey_at_stops.first
        first_stop_time = source.stop_times.sort_by{ |stop_time| stop_time.departure_time }.first

        expect(first_stop_time.arrival_time).to eq(GtfsTime.format_datetime(first_vehicle_journey_at_stop.arrival_time, first_vehicle_journey_at_stop.departure_day_offset, 'Europe/Paris'))
        expect(first_stop_time.departure_time).to eq(GtfsTime.format_datetime(first_vehicle_journey_at_stop.departure_time, first_vehicle_journey_at_stop.departure_day_offset, 'Europe/Paris'))
      end
    end

  end

  context 'with journeys' do
    include_context 'with exportable journeys'

    # Too random to be maintained
    it "should correctly export data as valid GTFS output", skip: true do
      # Create context for the tests
      selected_vehicle_journeys = []
      selected_stop_areas_hash = {}
      date_range = nil

      exported_referential.switch do
        date_range = gtfs_export.date_range
        selected_vehicle_journeys = Chouette::VehicleJourney.with_matching_timetable date_range
        gtfs_export.export_scope = Export::Scope::DateRange.new(exported_referential, date_range)
      end

      tmp_dir = Dir.mktmpdir

      ################################
      # Test agencies.txt export
      ################################

      agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')

      exported_referential.switch do
        GTFS::Target.open(agencies_zip_path) do |target|
          gtfs_export.export_companies_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build agencies_zip_path, strict: false
        expect(source.agencies.length).to eq(1)
        agency = source.agencies.first
        expect(agency.id).to eq(company.registration_number)
        expect(agency.name).to eq(company.name)
        expect(agency.lang).to eq(company.default_language)
      end

      ################################
      # Test stops.txt export
      ################################

      stops_zip_path = File.join(tmp_dir, '/test_stops.zip')

      # Fetch the expected exported stop_areas
      exported_referential.switch do
        selected_vehicle_journeys.each do |vehicle_journey|
          vehicle_journey.route.stop_points.each do |stop_point|
            candidates = [stop_point.stop_area]
            if stop_point.stop_area.area_type == "zdep" && stop_point.stop_area.parent
              candidates << stop_point.stop_area.parent
            end
            candidates.each do |stop_area|
              selected_stop_areas_hash[stop_area.id] ||= stop_area if stop_area.commercial?
            end
          end
        end
        selected_stop_areas = selected_stop_areas_hash.values

        GTFS::Target.open(stops_zip_path) do |target|
          gtfs_export.export_stop_areas_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build stops_zip_path, strict: false

        # Same size
        expect(source.stops.length).to eq(selected_stop_areas.length)
        # Randomly pick a stop_area and find the correspondant stop exported in GTFS
        random_stop_area = selected_stop_areas.sample

        # Find matching random stop in exported stops.txt file
        random_gtfs_stop = source.stops.detect {|e| e.id == (random_stop_area.registration_number.presence || random_stop_area.object_id)}
        expect(random_gtfs_stop).not_to be_nil
        expect(random_gtfs_stop.name).to eq(random_stop_area.name)
        expect(random_gtfs_stop.location_type).to eq(random_stop_area.area_type == 'zdep' ? '0' : '1')
        # Checks if the parents are similar
        expect(random_gtfs_stop.parent_station).to eq(((random_stop_area.parent.registration_number.presence || random_stop_area.parent.object_id) if random_stop_area.parent))
      end

      ################################
      # Test transfers.txt export
      ################################

      create :connection_link, stop_area_referential: exported_referential.stop_area_referential

      exported_referential.switch do
        transfers_zip_path = File.join(tmp_dir, '/test_transfers.zip')

        stop_area_ids = selected_vehicle_journeys.flat_map(&:stop_points).map(&:stop_area).select(&:commercial?).uniq.map(&:id)
        selected_connections = stop_area_referential.connection_links.where(departure_id: stop_area_ids, arrival_id: stop_area_ids)
        connections = selected_connections.map do |connection|
            [
              connection.departure.registration_number,
              connection.arrival.registration_number
            ].sort
        end.uniq.map do |from, to|
          { from: from, to: to, transfer_type: '2' }
        end

        create :connection_link,
          stop_area_referential: stop_area_referential,
          departure: selected_connections.last.arrival,
          arrival: selected_connections.last.departure

        GTFS::Target.open(transfers_zip_path) do |target|
          gtfs_export.export_transfers_to target
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build transfers_zip_path, strict: false

        expect(source.transfers.length).to eq connections.count
        expect(source.transfers.map do |transfer|
          {
            from: transfer.from_stop_id,
            to: transfer.to_stop_id,
            transfer_type: transfer.type
          }
        end).to match_array connections
      end

      ################################
      # Test lines.txt export
      ################################

      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      exported_referential.switch do
        GTFS::Target.open(lines_zip_path) do |target|
          gtfs_export.export_lines_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build lines_zip_path, strict: false
        selected_routes = {}
        selected_vehicle_journeys.each do |vehicle_journey|
          selected_routes[vehicle_journey.route.line.id] = vehicle_journey.route.line
        end

        expect(source.routes.length).to eq(selected_routes.length)
        route = source.routes.first
        line = exported_referential.lines.first

        expect(route.id).to eq(line.registration_number)
        expect(route.agency_id).to eq(line.company.registration_number)
        expect(route.long_name).to eq(line.published_name)
        expect(route.short_name).to eq(line.number)
        expect(route.type).to eq('3')
        expect(route.desc).to eq(line.comment)
        expect(route.url).to eq(line.url)
      end

      ####################################################
      # Test calendars.txt and calendar_dates.txt export #
      ####################################################

      exported_referential.switch do
        ################################
        # Test trips.txt export
        ################################

        targets_zip_path = File.join(tmp_dir, '/test_trips.zip')

        GTFS::Target.open(targets_zip_path) do |target|
          gtfs_export.export_vehicle_journeys_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build targets_zip_path, strict: false

        # Get VJ merged periods
        periods = []
        selected_vehicle_journeys.each do |vehicle_journey|
          vehicle_journey.time_tables.each do |tt|
            tt.periods.each do |period|
              periods << period if period.range & date_range
            end
          end
        end

        periods = periods.flatten.uniq

        # Same size
        expect(source.calendars.length).to eq(periods.length)
        # Randomly pick a time_table_period and find the correspondant calendar exported in GTFS
        random_period = periods.sample
        # Find matching random stop in exported stops.txt file
        random_gtfs_calendar = source.calendars.detect do |e|
          e.service_id == random_period.object_id
          e.start_date == (random_period.period_start.strftime('%Y%m%d'))
          e.end_date == (random_period.period_end.strftime('%Y%m%d'))

          e.monday == (random_period.time_table.monday ? "1" : "0")
          e.tuesday == (random_period.time_table.tuesday ? "1" : "0")
          e.wednesday == (random_period.time_table.wednesday ? "1" : "0")
          e.thursday == (random_period.time_table.thursday ? "1" : "0")
          e.friday == (random_period.time_table.friday ? "1" : "0")
          e.saturday == (random_period.time_table.saturday ? "1" : "0")
          e.sunday == (random_period.time_table.sunday ? "1" : "0")
        end

        expect(random_gtfs_calendar).not_to be_nil
        expect((random_period.period_start..random_period.period_end).overlaps?(date_range.begin..date_range.end)).to be_truthy

        # Get VJ merged periods
        vj_periods = []
        # selected_vehicle_journeys.each do |vehicle_journey|
        #   vehicle_journey.flattened_circulation_periods.select{|period| period.range & date_range}.each do |period|
        #     vj_periods << [period,vehicle_journey]
        #   end
        # end
        selected_vehicle_journeys.each do |vehicle_journey|
          vehicle_journey.time_tables.each do |tt|
            tt.periods.each do |period|
              periods << period if period.range & date_range
              vj_periods << [period,vehicle_journey] if period.range & date_range
            end
          end
        end

        # Same size
        expect(source.trips.count).to eq(vj_periods.length)

        # Randomly pick a vehicule_journey / period couple and find the correspondant trip exported in GTFS
        random_vj_period = vj_periods.sample

        # Find matching random stop in exported trips.txt file
        random_gtfs_trip = source.trips.detect {|t|
          (t.service_id == random_vj_period.first.id || t.service_id == random_vj_period.first.time_table.objectid) &&
          t.route_id == random_vj_period.last.route.line.registration_number.to_s &&
          t.short_name == random_vj_period.last.published_journey_name
        }
        expect(random_gtfs_trip).not_to be_nil

        ################################
        # Test stop_times.txt export
        ################################

        stop_times_zip_path = File.join(tmp_dir, '/stop_times.zip')
        GTFS::Target.open(stop_times_zip_path) do |target|
          gtfs_export.export_vehicle_journey_at_stops_to target
        end

        # The processed export files are re-imported through the GTFS gem, and the computed
        source = GTFS::Source.build stop_times_zip_path, strict: false

        expected_stop_times_length = vj_periods.map{|vj| vj.last.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }}.flatten.length

        # Same size
        expect(source.stop_times.count).to eq(expected_stop_times_length)

        # Count the number of stop_times generated by a random VJ and period couple (sop_times depends on a vj, a period and a stop_area)
        vehicle_journey_at_stops = random_vj_period.last.vehicle_journey_at_stops.select {|vehicle_journey_at_stop| vehicle_journey_at_stop.stop_point.stop_area.commercial? }

        # Fetch all the stop_times entries exported in GTFS related to the trip (matching the previous VJ / period couple)
        stop_times = source.stop_times.select{|stop_time| stop_time.trip_id == random_gtfs_trip.id }

        # Same size 2
        expect(stop_times.length).to eq(vehicle_journey_at_stops.length)

        # A random stop_time is picked
        random_vehicle_journey_at_stop = vehicle_journey_at_stops.sample
        stop_time = stop_times.detect{|stop_time| stop_time.arrival_time == GtfsTime.format_datetime(random_vehicle_journey_at_stop.arrival_time, random_vehicle_journey_at_stop.arrival_day_offset) }
        expect(stop_time).not_to be_nil
        expect(stop_time.departure_time).to eq(GtfsTime.format_datetime(random_vehicle_journey_at_stop.departure_time, random_vehicle_journey_at_stop.departure_day_offset))
      end
    end
  end
end
