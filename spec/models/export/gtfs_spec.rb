# frozen_string_literal: true

RSpec.describe Export::Gtfs, type: :model do
  let(:context) do
    Chouette.create do
      workgroup
    end
  end
  let(:referential) { nil }
  let(:prefer_referent_companies) { true }
  let(:export_scope) { nil }
  let(:export) do
    Export::Gtfs.new(
      name: 'Export GTFS',
      creator: 'Rspec',
      workgroup: context.workgroup,
      referential: referential,
      setup: {
        scope_setup: {
          type: 'Export::Setup::Scope::Referential',
          lines: {
            type: 'Export::Setup::Scope::Lines::Scheduled',
            prefer_referent_companies: prefer_referent_companies
          }
        }
      },
      export_scope: export_scope
    )
  end

  describe '#default_company' do
    subject { export.default_company }

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

    context 'when more scoped lines are associated to a Company with a Referent' do
      let(:context) do
        Chouette.create do
          company :referent, name: 'Referent', is_referent: true
          company :target, name: 'Default', referent: :referent
          company :wrong

          5.times { line company: :target }
          4.times { line company: :wrong }
          3.times { line }
        end
      end

      let(:referent) { context.company :referent }
      let(:company) { context.company :target }

      context 'when prefer_referent_companies option is used' do
        it { is_expected.to eq(referent) }
      end

      context 'when prefer_referent_companies option isn\'t used' do
        let(:prefer_referent_companies) { false }
        it { is_expected.to eq(company) }
      end
    end
  end

  describe '#default_timezone' do
    subject { export.default_timezone }

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
    let(:referential) { Chouette.create { referential }.referential }

    it 'should set gtfs_export status to failed' do
      export.save!
      expect(export.status).to eq('new')
      export.worker_died
      expect(export.status).to eq('failed')
    end
  end

  context 'with an exportable referential' do
    let(:context) do
      Chouette.create do
        workgroup do
          workbench do
            line :line1
            line :line2

            referential lines: %i[line1 line2] do
              route line: :line1 do
                vehicle_journey
              end
            end
          end
        end
      end
    end
    let(:referential) { context.referential }
    let(:export_scope) { Export::Scope::All.new(referential) }

    it "should create a default company and generate a message if the journey or its line doesn't have a company" do
      export.save!

      referential.switch do
        tmp_dir = Dir.mktmpdir

        agencies_zip_path = File.join(tmp_dir, '/test_agencies.zip')
        GTFS::Target.open(agencies_zip_path) do |target|
          export.export_companies_to target
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
          expect { export.export_lines_to target }.to change { Export::Message.count }.by(2)
        end

        # The processed export files are re-imported through the GTFS gem
        source = GTFS::Source.build lines_zip_path, strict: false
        route = source.routes.first
        expect(route.agency_id).to eq('chouette_default')
      end
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

    let(:referential) { context.referential }
    let(:export_scope) { Export::Scope::All.new(referential) }
    let(:vehicle_journey) { context.vehicle_journey }

    before { referential.switch }

    it 'gtfs export stop times use agency timezone' do
      stop_times_zip_path = export.generate_export_file

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
