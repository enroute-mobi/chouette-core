# frozen_string_literal: true

module Import
  class Workbench < Import::Base
    include ImportResourcesSupport

    after_commit :launch_worker, on: :create

    option :import_category, enumerize: %w[automatic shape_file netex_generic], default_value: 'automatic'
    option :automatic_merge, default_value: false,
                             depends: { option: :import_category, values: %w[automatic netex_generic] }, type: :boolean
    option :archive_on_fail, default_value: false,
                             depends: { option: :import_category, values: %w[automatic netex_generic] }, type: :boolean
    option :flag_urgent, default_value: false, depends: { option: :import_category, values: ['automatic'] },
                         type: :boolean
    option :merge_method, enumerize: %w[legacy experimental], default_value: 'legacy',
                          depends: { option: :import_category, values: ['automatic'] }
    option :shape_attribute_as_id, type: :string, depends: { option: :import_category, values: ['shape_file'] }
    option :update_workgroup_providers, default_value: false, type: :boolean
    option :store_xml, default_value: false, type: :boolean
    option :disable_missing_resources, default_value: false, type: :boolean
    option :strict_mode, default_value: false, type: :boolean
    option :ignore_particulars, default_value: false, type: :boolean
    option :ignore_parent_stop_areas, required: true, default_value: false, type: :boolean
    option :stop_area_provider_id, display: :stop_area_provider,
                                   collection: -> { candidate_stop_area_providers.order(:name) },
                                   allow_blank: true
    option :line_provider_id, display: :line_provider,
                              collection: -> { candidate_line_providers.order(:name) },
                              allow_blank: true
    option :specific_default_company_id, display: :specific_default_company,
                                         collection: -> { candidate_companies.order(:name) },
                                         allow_blank: true

    has_many :children_processings, through: :children, source: :processings
    has_many :control_list_runs, through: :children_processings, source: :processed, source_type: 'Control::List::Run'
    has_many :macro_list_runs, through: :children_processings, source: :processed, source_type: 'Macro::List::Run'

    has_many :referentials, through: :children

    def main_resource
      self
    end

    def file_extension_whitelist
      import_category == 'netex_generic' ? %w[zip xml] : %w[zip]
    end

    def assign_attributes(attributes)
      if (import_category = attributes.delete(:import_category))
        self.import_category = import_category
      end

      super attributes
    end

    def launch_worker
      update_column :status, 'running'
      update_column :started_at, Time.zone.now

      file.cache_stored_file!

      if file_type
        send "import_#{file_type}"
      else
        message = create_message(
          {
            criticity: :error,
            message_key: 'unsupported_file_format'
          }
        )
        message.save
        failed!
      end
    end

    def visible_options
      if import_category == 'shape_file'
        super.slice('import_category', 'shape_attribute_as_id')
      else
        super.reject { |k, _v| k == 'shape_attribute_as_id' }
      end
    end

    def import_netex
      delay(queue: :imports).netex_import
    end

    def netex_import
      WorkbenchImportService.new.perform(self)
    end

    def import_gtfs
      create_child_import Import::Gtfs
    end

    def import_neptune
      create_child_import Import::Neptune
    end

    def import_shapefile
      create_child_import Import::Shapefile
    end

    def import_netex_generic
      create_child_import Import::NetexGeneric
    end

    def create_child_import(klass)
      klass.create!(
        parent_type: self.class.name,
        parent_id: id,
        workbench: workbench,
        file: File.new(file.path),
        name: name,
        creator: 'Web service',
        code_space: code_space
      )
    rescue Exception => e
      Chouette::Safe.capture "Import::Workbench ##{id} Child import #{file_type} creation failed", e

      failed!
    end

    def failed!
      update_column :status, 'failed'
      update_column :ended_at, Time.zone.now
      archive_referentials if archive_on_fail
    end

    def archive_referentials
      referentials.each(&:archive!)
    end

    def overlapping_referentials
      children.flat_map(&:overlapping_referentials)
    end

    # Compute children status
    def children_status
      if children.unfinished.count.positive?
        'running'
      elsif children.where(status: self.class.failed_statuses).count.positive?
        'failed'
      elsif children.where(status: 'warning').count.positive?
        'warning'
      elsif children.where(status: 'successful').count == children.count
        'successful'
      end
    end

    # Compute processed status (Macro::List::Run and Control::List::Run)
    def processed_status
      statuses = (control_list_runs.pluck(:user_status) + macro_list_runs.pluck(:user_status)).uniq
      if statuses.include?('pending')
        'running'
      elsif statuses.include?('failed')
        'failed'
      elsif statuses.include?('warning')
        'warning'
      else
        'successful'
      end
    end

    def compute_new_status
      return children_status unless control_list_runs.present? || macro_list_runs.present?

      if children_status == 'running' || processed_status == 'running'
        'running'
      elsif children_status == 'failed' || processed_status == 'failed'
        'failed'
      elsif children_status == 'warning' || processed_status == 'warning'
        'warning'
      elsif children_status == 'successful' && processed_status == 'successful'
        'successful'
      end
    end

    delegate :line_providers, :stop_area_providers, :companies, to: :workbench, prefix: :candidate

    # Invokes by IevInterfaces::Task#update_status
    # *only* when status is changed to successful
    def done!(successful)
      if successful
        flag_refentials_as_urgent if flag_urgent
        create_automatic_merge if automatic_merge
      elsif archive_on_fail
        archive_referentials
      end
    end

    def flag_refentials_as_urgent
      referentials.each(&:flag_metadatas_as_urgent!)
    end

    def create_automatic_merge
      Merge.transaction do
        pending_merge = workbench.merges.order(:created_at).pending.lock.first

        if pending_merge.present?
          pending_merge.referential_ids |= referentials.map(&:id)
          logger.info "Add referentials #{referentials.map(&:id)} to pending merge #{pending_merge.id}"
          referentials.each(&:pending!)
          pending_merge.save!
        else
          logger.info 'Create new merge'
          workbench.merges.create!({
                                     creator: creator,
                                     notification_target: notification_target,
                                     referentials: referentials,
                                     user: user,
                                     automatic_operation: true,
                                     merge_method: merge_method
                                   })
        end
      end
    end
  end
end
