class Import::Workbench < Import::Base
  after_commit :launch_worker, :on => :create

  def launch_worker
    unless Import::Gtfs.accept_file?(file.path)
      WorkbenchImportWorker.perform_async(id)
    else
      import_gtfs
    end
  end

  # def main_resource
  #   @resource ||= resources.find_or_create_by(name: self.name, resource_type: "workbench_import")
  # end

  def import_gtfs
    update_column :status, 'running'
    update_column :started_at, Time.now

    Import::Gtfs.create! parent_type: self.class.name, parent_id: self.id, workbench: workbench, file: File.new(file.path), name: "Import GTFS", creator: "Web service"

    # update_column :status, 'successful'
    # update_column :ended_at, Time.now
  rescue Exception => e
    Rails.logger.error "Error while processing GTFS file: #{e}"

    update_column :status, 'failed'
    update_column :ended_at, Time.now
  end
end
