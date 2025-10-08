# frozen_string_literal: true

class AddExportSetupToExportsAndPublications < ActiveRecord::Migration[7.0]
  def up # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    on_public_schema_only do
      change_table :exports do |t|
        t.jsonb :setup
      end

      change_table :publication_setups do |t|
        t.jsonb :export_setup
      end

      ::Export::Base.find_each do |e|
        e.setup = send(migrate_method_for_export_class(e.class.name), e.options)
        e.save(validate: false, timestamps: false)
      end

      ::PublicationSetup.find_each do |ps|
        ps.export_setup = migrate_publication_setup_export_options_to_export_setup(ps.export_options)
        ps.save(validate: false, timestamps: false)
      end
    end
  end

  def down
    on_public_schema_only do
      change_table :exports do |t|
        t.remove :setup
      end

      change_table :publication_setups do |t|
        t.remove :export_setup
      end
    end
  end

  private

  def migrate_export_options_to_export_setup(export_options) # rubocop:disable Metrics/MethodLength
    included_lines = case export_options['exported_lines']
                     when 'line_ids'
                       {
                         type: 'Export::Setup::Scope::LineSelector::Lines',
                         line_ids: export_options['line_ids']
                       }
                     when 'company_ids'
                       {
                         type: 'Export::Setup::Scope::LineSelector::Companies',
                         company_ids: export_options['company_ids']
                       }
                     when 'line_provider_ids'
                       {
                         type: 'Export::Setup::Scope::LineSelector::LineProviders',
                         line_provider_ids: export_options['line_provider_ids']
                       }
                     else
                       {
                         type: 'Export::Setup::Scope::LineSelector::All'
                       }
                     end

    {
      scope_setup: {
        type: 'Export::Setup::Scope::Referential',
        vehicle_journeys: {
          included_lines: included_lines
        }
      }
    }
  end

  def migrate_gtfs_export_options_to_export_setup(export_options) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    result = migrate_export_options_to_export_setup(export_options)

    period = case export_options['period']
             when 'only_next_days'
               {
                 type: 'Export::Setup::Scope::PeriodSelector::Duration',
                 day_count: export_options['duration']
               }
             when 'static_day_period'
               {
                 type: 'Export::Setup::Scope::PeriodSelector::Static',
                 from: export_options['from'],
                 to: export_options['to']
               }
             else
               {
                 type: 'Export::Setup::Scope::PeriodSelector::All'
               }
             end
    result[:scope_setup][:vehicle_journeys][:period] = period

    result[:code_space_id] = export_options['exported_code_space']

    result[:scope_setup][:stop_areas] = {
      type: 'Export::Setup::Scope::StopAreas::Scheduled',
      prefer_referent_stop_areas: export_options['prefer_referent_stop_area'],
      ignore_parent_stop_areas: export_options['ignore_parent_stop_places']
    }

    result[:scope_setup][:lines] = {
      type: 'Export::Setup::Scope::Lines::Scheduled',
      prefer_referent_lines: export_options['prefer_referent_line'],
      prefer_referent_companies: export_options['prefer_referent_company']
    }

    result[:ignore_extended_route_types] = export_options['ignore_extended_gtfs_route_types']
    result[:stop_sequence_from_one] = export_options['stop_sequence_from_one']

    result
  end

  def migrate_netex_generic_export_options_to_export_setup(export_options) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    result = migrate_export_options_to_export_setup(export_options)

    period = case export_options['period']
             when 'only_next_days'
               {
                 type: 'Export::Setup::Scope::PeriodSelector::Duration',
                 day_count: export_options['duration']
               }
             when 'static_day_period'
               {
                 type: 'Export::Setup::Scope::PeriodSelector::Static',
                 from: export_options['from'],
                 to: export_options['to']
               }
             else
               {
                 type: 'Export::Setup::Scope::PeriodSelector::All'
               }
             end
    result[:scope_setup][:vehicle_journeys][:period] = period

    result[:code_space_id] = export_options['exported_code_space']

    result[:scope_setup][:stop_areas] = {
      type: 'Export::Setup::Scope::StopAreas::Scheduled',
      ignore_referent_stop_areas: export_options['ignore_referent_stop_areas']
    }

    result[:scope_setup][:lines] = {
      type: 'Export::Setup::Scope::Lines::Scheduled',
      prefer_referent_lines: export_options['prefer_referent_line']
    }

    result[:profile] = export_options['profile']
    result[:profile] = 'idfm/publication/legacy' if result[:profile] == 'idfm/full' # CHOUETTE-4619 once and for all
    result[:participant_ref] = export_options['participant_ref']
    result[:profile_options] = if export_options['profile_options']
                                 ActiveSupport::JSON.decode(export_options['profile_options'])
                               else
                                 {}
                               end
    result[:skip_line_resources] = export_options['skip_line_resources']
    result[:skip_stop_area_resources] = export_options['skip_stop_area_resources']

    result
  end

  def migrate_ara_export_options_to_export_setup(export_options)
    result = migrate_export_options_to_export_setup(export_options)

    result[:include_stop_visits] = export_options['include_stop_visits']

    result
  end

  def migrate_publication_setup_export_options_to_export_setup(export_options) # rubocop:disable Metrics/MethodLength
    result = send(migrate_method_for_export_class(export_options['type']), export_options)

    type = case export_options['type'] # rubocop:disable Style/HashLikeCase
           when 'Export::Gtfs'
             'Export::Setup::Gtfs'
           when 'Export::NetexGeneric'
             'Export::Setup::Netex'
           when 'Export::Ara'
             'Export::Setup::Ara'
           end
    result[:type] = type

    result[:scope_setup][:type] = 'Export::Setup::Scope::PublishedReferential'

    result
  end

  def migrate_method_for_export_class(export_class_name)
    :"migrate_#{export_class_name.demodulize.underscore}_export_options_to_export_setup"
  end
end
