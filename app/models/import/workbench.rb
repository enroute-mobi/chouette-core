class Import::Workbench < Import::Base
  include ImportResourcesSupport

  after_commit :launch_worker, :on => :create

  option :automatic_merge, type: :boolean, default_value: false
  option :archive_on_fail, type: :boolean, default_value: false
  option :flag_urgent, type: :boolean, default_value: false
  option :merge_method, type: :string, collection: %w(legacy experimental),
                        default_value: 'legacy'

  def main_resource; self end

  def launch_worker
    update_column :status, 'running'
    update_column :started_at, Time.now
    notify_state

    file.cache_stored_file!

    if file_type
      send "import_#{file_type}"
    else
      message = create_message(
        {
          criticity: :error,
          message_key: "unsupported_file_format"
        }
      )
      message.save
      failed!
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

  def create_child_import(klass)
    klass.create! parent_type: self.class.name, parent_id: self.id, workbench: workbench, file: File.new(file.path), name: self.name, creator: "Web service"
  rescue Exception => e
    Chouette::Safe.capture "Import::Workbench ##{id} Child import #{file_type} creation failed", e

    failed!
  end

  def compliance_check_sets
    ComplianceCheckSet.where parent_id: self.id, parent_type: "Import::Workbench"
  end

  def failed!
    update_column :status, 'failed'
    update_column :ended_at, Time.now
    archive_referentials if archive_on_fail
    notify_state
  end

  def archive_referentials
    referentials.each(&:archive!)
  end

  # Compute new_status from children (super) and compliance_check_sets
  # Used by IevInterfaces::Task#update_status
  def compute_new_status
    new_status_from_children = super

    if new_status_from_children == 'successful'
      Rails.logger.info "#{self.class.name} ##{id}: compliance_check_sets statuses #{compliance_check_sets.reload.map(&:status).inspect}"
      if compliance_check_sets.unfinished.count > 0
        'running'
      else
        if compliance_check_sets.where(status: ComplianceCheckSet.failed_statuses).count > 0
          'failed'
        elsif children.where(status: "warning").count > 0
          'warning'
        elsif children.where(status: "successful").count == children.count
          'successful'
        end
      end
    else
      new_status_from_children
    end
  end

  def referentials
    self.resources.map(&:referential).compact
  end

  # Invokes by IevInterfaces::Task#update_status
  # *only* when status is changed to successful
  def done! successful
    if successful
      flag_refentials_as_urgent if flag_urgent
      create_automatic_merge if automatic_merge
    else
      archive_referentials if archive_on_fail
    end
  end

  def flag_refentials_as_urgent
    referentials.each(&:flag_metadatas_as_urgent!)
  end

  def create_automatic_merge
    Merge.create creator: creator,
                 workbench: workbench,
                 referentials: referentials,
                 notification_target: notification_target,
                 user: user,
                 automatic_operation: true,
                 merge_method: merge_method
  end
end
