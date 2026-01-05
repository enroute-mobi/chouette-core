# frozen_string_literal: true

class RewriteExportSetupsSkipLineResourcesAndSkipStopAreaResources < ActiveRecord::Migration[7.2]
  def change # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      ::Export::NetexGeneric.where("setup ? 'skip_line_resources' OR setup ? 'skip_stop_area_resources'")
                            .find_each do |e|
        e.setup = migrate_skip_resources(e.setup.as_json)
        e.save(validate: false, timestamps: false)
      end

      ::PublicationSetup.where("export_setup ? 'skip_line_resources' OR export_setup ? 'skip_stop_area_resources'")
                        .find_each do |ps|
        ps.export_setup = migrate_skip_resources(ps.export_setup.as_json)
        ps.save(validate: false, timestamps: false)
      end
    end
  end

  def migrate_skip_resources(export_setup_json)
    skip_line_resources = export_setup_json.delete('skip_line_resources')
    if skip_line_resources
      export_setup_json['scope_setup']['lines']['type'] = 'Export::Setup::Scope::Lines::None'
    end

    skip_stop_area_resources = export_setup_json.delete('skip_stop_area_resources')
    if skip_stop_area_resources
      export_setup_json['scope_setup']['stop_areas']['type'] = 'Export::Setup::Scope::StopAreas::None'
    end

    export_setup_json
  end
end
