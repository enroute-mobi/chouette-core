# coding: utf-8

RSpec.describe Import::Neptune do

  let(:workbench) do
    create :workbench do |workbench|
      workbench.line_referential.update objectid_format: "netex"
      workbench.stop_area_referential.update objectid_format: "netex"
    end
  end

  let(:workbench_import){ create :workbench_import }

  def create_import(file=nil)
    i = build_import(file)
    i.save!
    i
  end

  def build_import(file=nil)
    file ||= 'sample_neptune'
    Import::Neptune.new workbench: workbench, local_file: fixtures_path("#{file}.zip"), creator: "test", name: "test", parent: workbench_import
  end

  before(:each) do
    allow(import).to receive(:save_model).and_wrap_original { |m, *args| m.call(*args); args.first.run_callbacks(:commit) }
  end

  context "when the file is not directly accessible" do
    let(:import) { create_import }

    before(:each) do
      allow(import).to receive(:file).and_return(nil)
    end

    it "should still be able to update the import" do
      import.update status: :failed
      expect(import.reload.status).to eq "failed"
    end
  end

  describe "created referential" do
    let(:import) { build_import }

    before(:each) do
      create :line, line_referential: workbench.line_referential
      import.send(:import_lines)
    end

    it "is named after the import name" do
      import.name = "Import Name"
      import.create_referential
      expect(import.referential.name).to eq(import.name)
    end

    it 'uses the imported lines in the metadata' do
      new_lines = workbench.line_referential.lines.last(2)
      import.create_referential
      expect(import.referential.metadatas.count).to eq 1
      expect(import.referential.metadatas.last.line_ids).to eq new_lines.map(&:id)
    end

    it 'uses the imported dates in the metadata' do
      new_lines = workbench.line_referential.lines.last(2)
      import.create_referential
      expect(import.referential.metadatas.count).to eq 1
      period_start = '2018-10-22'.to_date
      period_end = '2018-12-22'.to_date
      import.instance_variable_set '@timetables_period_start', period_start
      import.instance_variable_set '@timetables_period_end', period_end
      import.send(:fix_metadatas_periodes)
      expect(import.referential.metadatas.last.periodes).to eq [(period_start..period_end)]
    end
  end

  describe "#import_lines" do
    let(:import) { build_import }

    it 'should create new lines' do
      expect{ import.send(:import_lines) }.to change{ workbench.line_referential.lines.count }.by 2
    end

    it 'should update existing lines' do
      import.send(:import_lines)
      line = workbench.line_referential.lines.last
      attrs = line.attributes.except('updated_at')
      line.update transport_mode: :tram, published_name: "foo"
      expect{ import.send(:import_lines) }.to_not change{ workbench.line_referential.lines.count }
      expect(line.reload.attributes.except('updated_at')).to eq attrs
    end

    it "should set company and network" do
      import.send(:import_companies)
      import.send(:import_networks)
      import.send(:import_lines)
      line = workbench.line_referential.lines.last
      expect(line.company).to be_present
      expect(line.network).to be_present
    end

    it "ignores dummy line published_name" do
      # Line "NAVSTEX:Line:VOIRON" has a normal published name
      # Line "NAVSTEX:Line:GRENOB" has its number as published name
      import = build_import("sample_neptune_dummy_published_name")
      import.send(:import_lines)

      line_with_published_name = workbench.line_referential.lines.find_by(registration_number: "NAVSTEX:Line:VOIRON")
      expect(line_with_published_name).to have_attributes(published_name: "ST EXUPERY - VOIRON")

      line_with_ignored_published_name = workbench.line_referential.lines.find_by(registration_number: "NAVSTEX:Line:GRENOB")
      expect(line_with_ignored_published_name).to have_attributes(published_name: nil)
    end

    it "manages empty line comment" do
      import = build_import("sample_neptune_empty_comments")
      import.send(:import_lines)
      expect(workbench.line_referential.lines).to all(have_attributes(comment: nil))
    end

    it "keeps line attributes when neptune file doesn't provide them" do
      company = workbench.line_referential.companies.create!(name: "Defined", line_provider: workbench.default_line_provider)
      network = workbench.line_referential.networks.create!(name: "Defined", line_provider: workbench.default_line_provider)

      existing_attributes = {
        number: "Defined",
        published_name: "Defined",
        comment: "Defined",
        transport_mode: "bus",
        transport_submode: "undefined",
        company: company,
        network: network
      }

      line_attributes = existing_attributes.merge(
        registration_number: "NAVSTEX:Line:GRENOB",
        name: "Defined",
        line_provider: workbench.default_line_provider
      )
      line = workbench.line_referential.lines.create!(line_attributes)

      import = build_import("sample_neptune_empty_stop_line")
      import.send(:import_lines)

      line.reload

      expect(line).to have_attributes(existing_attributes)
      name_in_neptune_file = "ST EXUPERY - GRENOBLE"
      expect(line.name).to eq(name_in_neptune_file)
    end

  end

  describe "#import_stop_areas" do
    let(:import) { build_import }

    let(:imported_stop_areas) { workbench.stop_area_referential.stop_areas }

    it 'should create new stop_areas' do
      expect{ import.send(:import_stop_areas) }.to change{ imported_stop_areas.count }.by 18
      stop_area = Chouette::StopArea.find_by registration_number: 'NAVSTEX:StopArea:gen6'
      expect(stop_area.latitude).to be_present
      expect(stop_area.longitude).to be_present
      expect(stop_area.nearest_topic_name).to be_present
    end

    it 'creates Stop_Areas with time zone Europe/Paris' do
      import.send(:import_stop_areas)
      expect(imported_stop_areas).to all(have_attributes(time_zone: "Europe/Paris"))
    end

    it 'updates Stop_Areas with time zone Europe/Paris' do
      import.send(:import_stop_areas)

      stop_area = imported_stop_areas.last
      stop_area.update time_zone: nil

      expect { import.send(:import_stop_areas) }.to change { stop_area.reload.time_zone }.from(nil).to("Europe/Paris")
    end

    it 'should update existing stop_areas' do
      import.send(:import_stop_areas)
      expect { import.send(:import_stop_areas) }.to_not(change { imported_stop_areas.count })

      stop_area = imported_stop_areas.last
      imported_name = stop_area.name

      stop_area.update name: "Dummy"

      expect { import.send(:import_stop_areas) }.to change { stop_area.reload.name }.from("Dummy").to(imported_name)
    end

    it 'should link stop_areas' do
      import.send(:import_stop_areas)
      parent = imported_stop_areas.find_by(registration_number: 'NAVSTEX:StopArea:gen3')
      child = imported_stop_areas.find_by(registration_number: 'NAVSTEX:StopArea:3')
      expect(child.parent).to eq parent
    end

    it 'should update stop_areas parent' do
      import.send(:import_stop_areas)

      first = imported_stop_areas.find_by(registration_number: "NAVSTEX:StopArea:gen3")
      second = imported_stop_areas.find_by(registration_number: "NAVSTEX:StopArea:gen1")

      expect(first.parent&.registration_number).to eq('ITINISERE:StopArea:log58508')

      # Remove parent
      first_parent = first.parent
      first.update!(parent_id: nil)

      # Change parent
      second_parent = second.parent
      second.update!(parent_id: first_parent.id)

      # Update
      import.send(:import_stop_areas)

      expect(first.reload.parent).not_to be_nil
      expect(first.reload.parent_id).to eq(first_parent.id)
      expect(second.reload.parent_id).to eq(second_parent.id)
    end

    it "keeps line attributes when neptune file doesn't provide them" do
      parent = imported_stop_areas.create!(name: "Parent", area_type: "zdlp", stop_area_provider: workbench.default_stop_area_provider)

      existing_attributes = {
        comment: "Defined",
        street_name: "Defined",
        nearest_topic_name: "Defined",
        area_type: "zdep",
        latitude: 0.42e2,
        longitude: 0.42e2,
        parent: nil
      }

      stop_area_attributes = existing_attributes.merge(
        registration_number: "Empty",
        name: "Defined",
        stop_area_provider: workbench.default_stop_area_provider
      )
      stop_area = imported_stop_areas.create!(stop_area_attributes)

      import = build_import("sample_neptune_empty_stop_line")
      import.send(:import_stop_areas)
      stop_area.reload

      expect(stop_area).to have_attributes(existing_attributes)
      name_in_neptune_file = "Empty Area"
      expect(stop_area.name).to eq(name_in_neptune_file)
    end

  end

  describe "#import_companies" do
    let(:import) { build_import }

    let(:imported_companies) { workbench.line_referential.companies }

    it 'should create new companies' do
      expect{ import.send(:import_companies) }.to change{ imported_companies.count }.by 1
    end

    it 'creates Companies with time zone Europe/Paris' do
      import.send(:import_companies)
      expect(imported_companies).to all(have_attributes(time_zone: "Europe/Paris"))
    end

    it 'updates Companies with time zone Europe/Paris' do
      import.send(:import_companies)

      company = imported_companies.last
      company.update time_zone: nil

      expect { import.send(:import_companies) }.to change { company.reload.time_zone }.from(nil).to("Europe/Paris")
    end

    it 'should update existing companies' do
      import.send(:import_companies)

      expect { import.send(:import_companies) }.to_not(change { imported_companies.count })

      company = imported_companies.last
      imported_name = company.name

      company.update name: "Dummy"

      expect { import.send(:import_companies) }.to change { company.reload.name }.from("Dummy").to(imported_name)
    end
  end

  describe "#import_networks" do
    let(:import) { build_import }

    it 'should create new networks' do
      expect{ import.send(:import_networks) }.to change{ workbench.line_referential.networks.count }.by 1
    end

    it 'should update existing networks' do
      import.send(:import_networks)
      network = workbench.line_referential.networks.last
      attrs = network.attributes.except('updated_at')
      network.update name: "foo"
      expect{ import.send(:import_networks) }.to_not change{ workbench.line_referential.networks.count }
      expect(network.reload.attributes.except('updated_at')).to eq attrs
    end
  end

  describe "#import_lines_content" do
    let(:import) { create_import }

    before(:each){
      import.prepare_referential
      import.send(:import_stop_areas)
      import.send(:import_time_tables)
    }

    it 'should create new routes' do
      expect{ import.send(:import_lines_content) }.to change{ Chouette::Route.count }.by 4
    end

    it 'should set opposite_route' do
      import.send(:import_lines_content)
      route = Chouette::Route.find_by published_name: 'ST EXUPERY - GRENOBLE - Aller'
      opposite_route = Chouette::Route.find_by published_name: 'ST EXUPERY - GRENOBLE - Retour'
      expect(route.opposite_route).to eq opposite_route
    end

    it 'should set stop_points' do
      import.send(:import_lines_content)
      route = Chouette::Route.find_by published_name: 'ST EXUPERY - GRENOBLE - Aller'
      expect(route.stop_points.count).to eq 3
    end

    it 'should create new journey_patterns' do
      expect{ import.send(:import_lines_content) }.to change{ Chouette::JourneyPattern.count }.by 4
    end

    it 'should set stop_points on journey_patterns' do
      import.send(:import_lines_content)
      journey_pattern = Chouette::JourneyPattern.find_by registration_number: '8218'
      expect(journey_pattern.stop_points.count).to eq 3
    end

    context 'with a complete file' do
      let(:import) { create_import 'sample_neptune_large' }

      it 'should create new vehicle_journeys' do
        expect{ import.send(:import_lines_content) }.to change{ Chouette::VehicleJourney.count }.by 3
        vehicle_journey = Chouette::VehicleJourney.find_by number: '1026'
        expect(vehicle_journey.codes.first.value).to eq "toutenbus:VehicleJourney:700"
        expect(vehicle_journey.vehicle_journey_at_stops.count).to eq 12
        expect(vehicle_journey.time_tables.count).to eq 2
        expect(vehicle_journey.published_journey_identifier).to eq('1026')
        expect(vehicle_journey.number).to eq(1026)
      end
    end
  end

  describe "#import_time_tables" do
    let(:import) { create_import('sample_neptune_large') }

    before(:each) do
      import.prepare_referential
    end

    it 'should create new time_tables' do
      expect{ import.send(:import_time_tables) }.to change{ Chouette::TimeTable.count }.by 3
    end

    it 'should update existing time_tables' do
      import.send(:import_time_tables)
      expect{ import.send(:import_time_tables) }.to change{ Chouette::TimeTable.count }.by 0
    end
  end

  describe '#add_time_table_dates' do
    let(:import) { build_import }
    let(:timetable) { create(:time_table) }

    it 'should add the new dates' do
      expect{ import.send(:add_time_table_dates, timetable, '2018-10-22') }.to change{ timetable.dates.count }.by 1
      date = timetable.dates.last
      expect(date.in_out).to be_truthy
      expect(date.date).to eq '2018-10-22'.to_date
      expect{ import.send(:add_time_table_dates, timetable, '2018-10-22') }.to change{ timetable.dates.count }.by 0
      expect{ import.send(:add_time_table_dates, timetable, '2018-10-23') }.to change{ timetable.dates.count }.by 1
    end
  end

  describe '#add_time_table_periods' do
    let(:import) { build_import }
    let(:timetable) { create(:time_table) }

    it 'should add the new periods' do
      expect{
        import.send(:add_time_table_periods, timetable, { start_of_period: '2018-11-23', end_of_period: '2018-11-25'})
      }.to change{ timetable.periods.count }.by 1
    end

    it 'should merge periods' do
      expect{
        import.send(:add_time_table_periods, timetable, [
          { start_of_period: '2018-11-23', end_of_period: '2018-11-25'},
          { start_of_period: '2018-11-24', end_of_period: '2018-11-26'},
        ])
      }.to change{ timetable.periods.count }.by 1
    end

    it 'should split separate periods' do
      expect{
        import.send(:add_time_table_periods, timetable, [
          { start_of_period: '2018-11-23', end_of_period: '2018-11-25'},
          { start_of_period: '2018-11-27', end_of_period: '2018-11-29'},
        ])
      }.to change{ timetable.periods.count }.by 2
    end
  end

  describe "#int_day_types_mapping" do
    let(:import) { build_import }

    it 'should return the correct values' do
      expect(import.send(:int_day_types_mapping, 'Monday')).to eq import.send(:int_day_types_mapping, ['Monday'])
      expect(import.send(:int_day_types_mapping, 'Monday')).to eq Chouette::TimeTable::MONDAY
      expect(import.send(:int_day_types_mapping, 'Tuesday')).to eq Chouette::TimeTable::TUESDAY
      expect(import.send(:int_day_types_mapping, 'Wednesday')).to eq Chouette::TimeTable::WEDNESDAY
      expect(import.send(:int_day_types_mapping, 'Thursday')).to eq Chouette::TimeTable::THURSDAY
      expect(import.send(:int_day_types_mapping, 'Friday')).to eq Chouette::TimeTable::FRIDAY
      expect(import.send(:int_day_types_mapping, 'Saturday')).to eq Chouette::TimeTable::SATURDAY
      expect(import.send(:int_day_types_mapping, 'Sunday')).to eq Chouette::TimeTable::SUNDAY
      weekday = Chouette::TimeTable::MONDAY | Chouette::TimeTable::TUESDAY | Chouette::TimeTable::WEDNESDAY
      weekday |= Chouette::TimeTable::THURSDAY  | Chouette::TimeTable::FRIDAY
      expect(import.send(:int_day_types_mapping, 'WeekDay')).to eq weekday
      weekend = Chouette::TimeTable::SATURDAY | Chouette::TimeTable::SUNDAY
      expect(import.send(:int_day_types_mapping, 'WeekEnd')).to eq weekend

      expect(import.send(:int_day_types_mapping, %w[Friday Saturday])).to eq Chouette::TimeTable::FRIDAY | Chouette::TimeTable::SATURDAY
      expect(import.send(:int_day_types_mapping, %w[WeekEnd Saturday])).to eq weekend
    end
  end
end
