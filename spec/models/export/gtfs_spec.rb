# frozen_string_literal: true

RSpec.describe Export::Gtfs, type: %i[model with_exportable_referential] do
  let(:gtfs_export) do
    create :gtfs_export, referential: exported_referential, workbench: workbench, duration: 5,
                         prefer_referent_stop_area: true, prefer_referent_company: true
  end

  describe '#default_company' do
    subject { export.default_company }

    # TODO: Should be provided by top describe
    let(:export) { Export::Gtfs.new export_scope: export_scope, workgroup: context.workgroup }

    let(:export_scope) { double lines: context.line_referential.lines }

    context 'when scoped lines have no company' do
      let(:context) do
        Chouette.create do
          5.times { line }
        end
      end

      it { is_expected.to be_nil }
    end

    context 'when more scoped lines are associated to a Company "default"' do
      let(:context) do
        Chouette.create do
          company :target, name: 'Default'
          company :wrong

          5.times { line company: :target }
          4.times { line company: :wrong }
          3.times { line }
        end
      end

      let(:company) { context.company :target }

      it { is_expected.to eq(company) }
    end
  end

  describe '#default_timezone' do
    subject { export.default_timezone }

    # TODO: Should be provided by top describe
    let(:export) { Export::Gtfs.new }

    context 'when default_company is defined with "Europe/Berlin" timezone' do
      before { allow(export).to receive(:default_company).and_return(company) }

      let(:company) { Chouette::Company.new time_zone: 'Europe/Berlin' }

      it { is_expected.to eq(company.time_zone) }
    end

    context 'when default_company is not defined' do
      before { allow(export).to receive(:default_company).and_return(nil) }

      it { is_expected.to eq(Export::Gtfs::DEFAULT_TIMEZONE) }
    end
  end

  describe '#worker_died' do
    it 'should set gtfs_export status to failed' do
      expect(gtfs_export.status).to eq('new')
      gtfs_export.worker_died
      expect(gtfs_export.status).to eq('failed')
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
      expect(agency.id).to eq('chouette_default')
      expect(agency.timezone).to eq('Etc/UTC')

      # Test the line-company link
      lines_zip_path = File.join(tmp_dir, '/test_lines.zip')
      GTFS::Target.open(lines_zip_path) do |target|
        expect { gtfs_export.export_lines_to target }.to change { Export::Message.count }.by(2)
      end

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build lines_zip_path, strict: false
      route = source.routes.first
      expect(route.agency_id).to eq('chouette_default')
    end
  end

  describe 'When agency timezone is defined' do
    let(:context) do
      Chouette.create do
        company :company, time_zone: 'Europe/Paris'
        line :line, company: :company

        stop_area :departure, time_zone: 'Europe/Athens'
        stop_area :second
        stop_area :arrival

        referential lines: [:line] do
          time_table :default
          route line: :line, stop_areas: %i[departure second arrival] do
            vehicle_journey time_tables: [:default]
          end
        end
      end
    end

    let(:exported_referential) { context.referential }
    let(:vehicle_journey) { context.vehicle_journey }

    before { exported_referential.switch }

    let(:gtfs_export) { Export::Gtfs.new(referential: exported_referential, workgroup: exported_referential.workgroup) }

    it 'gtfs export stop times use agency timezone' do
      gtfs_export.duration = nil
      gtfs_export.export_scope = Export::Scope::All.new(exported_referential)

      stop_times_zip_path = gtfs_export.generate_export_file

      # The processed export files are re-imported through the GTFS gem
      source = GTFS::Source.build stop_times_zip_path, strict: false

      first_vehicle_journey_at_stop = vehicle_journey.vehicle_journey_at_stops.first
      first_stop_time = source.stop_times.min_by(&:departure_time)

      expect(first_stop_time.arrival_time).to eq(GtfsTime.format_datetime(first_vehicle_journey_at_stop.arrival_time,
                                                                          first_vehicle_journey_at_stop.departure_day_offset, 'Europe/Paris'))
      expect(first_stop_time.departure_time).to eq(GtfsTime.format_datetime(
                                                     first_vehicle_journey_at_stop.departure_time, first_vehicle_journey_at_stop.departure_day_offset, 'Europe/Paris'
                                                   ))
    end
  end
end
