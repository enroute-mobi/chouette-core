class Import::Workbench < Import::Base
  include ImportResourcesSupport

  after_commit :launch_worker, :on => :create

  option :automatic_merge, type: :boolean, default_value: false

  def main_resource; self end

  def launch_worker
    update_column :status, 'running'
    update_column :started_at, Time.now

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
  end

  def done!
    if (successful? || warning?) && automatic_merge
      Merge.create creator: self.creator, workbench: self.workbench, referentials: self.resources.map(&:referential).compact, notification_target: self.notification_target, user: user
    end
  end
end
