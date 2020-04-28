class Import::Workbench < Import::Base
  include ImportResourcesSupport

  after_commit :launch_worker, :on => :create

  option :automatic_merge, type: :boolean, default_value: false
  option :flag_urgent, type: :boolean, default_value: false

  def main_resource; self end

  def launch_worker
    update_column :status, 'running'
    update_column :started_at, Time.now
    notify_state

    file.cache_stored_file!

    case file_type
    when :gtfs
      import_gtfs
    when :netex
      delay(queue: :imports).netex_import
    when :neptune
      import_neptune
    else
      message = create_message(
        {
          criticity: :error,
          message_key: "unknown_file_format"
        }
      )
      message.save
      failed!
    end
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
    Rails.logger.error "Error while processing #{file_type} file: #{e}"
    Rails.logger.error e.backtrace.join("\n")

    failed!
  end

  def compliance_check_sets
    ComplianceCheckSet.where parent_id: self.id, parent_type: "Import::Workbench"
  end

  def failed!
    update_column :status, 'failed'
    update_column :ended_at, Time.now
    notify_state
  end


  def child_change
    super
    if self.class.finished_statuses.include?(status)
      done! if self.compliance_check_sets.all?(&:successful?)
    end
  end

  def referentials
    self.resources.map(&:referential).compact
  end

  def done!
    return unless (successful? || warning?) && children.reload.all?(&:finished?)

    if flag_urgent
      flag_refentials_as_urgent
    end
    if automatic_merge
      create_automatic_merge
    end
  end

  def flag_refentials_as_urgent
    referentials.each(&:flag_metadatas_as_urgent!)
  end

  def create_automatic_merge
    Merge.create creator: creator, workbench: workbench, referentials: referentials, notification_target: notification_target, user: user, automatic_operation: true
  end


end
