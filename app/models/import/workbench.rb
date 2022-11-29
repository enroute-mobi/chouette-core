class Import::Workbench < Import::Base
  include ImportResourcesSupport

  after_commit :launch_worker, :on => :create

  option :import_category, collection: %w(automatic shape_file netex_generic), default_value: 'automatic'
  option :automatic_merge, default_value: false, depends: {option: :import_category, value: "automatic"}, type: :boolean
  option :archive_on_fail, default_value: false, depends: {option: :import_category, value: "automatic"}, type: :boolean
  option :flag_urgent, default_value: false, depends: {option: :import_category, value: "automatic"}, type: :boolean
  option :merge_method, collection: %w(legacy experimental), default_value: 'legacy', depends: {option: :import_category, value: "automatic"}
  option :shape_attribute_as_id, type: :string, depends: {option: :import_category, value: "shape_file"}
  option :update_workgroup_providers, default_value: false, type: :boolean
  option :store_xml, default_value: false, type: :boolean

  has_many :compliance_check_sets, -> { where(parent_type: "Import::Workbench") }, foreign_key: :parent_id, dependent: :destroy

  has_many :processings, through: :children
  has_many :control_list_runs, through: :processings, source: :processed, source_type: 'Control::List::Run'
  has_many :macro_list_runs, through: :processings, source: :processed, source_type: 'Macro::List::Run'

  def main_resource; self end

  def file_extension_whitelist
    import_category == 'netex_generic' ? %w(zip xml) : %w(zip)
  end

  def assign_attributes(attributes)
    if (import_category = attributes.delete(:import_category))
      self.import_category = import_category
    end

    super attributes
  end

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

  def visible_options
    if import_category == "shape_file"
      super.slice("import_category","shape_attribute_as_id")
    else
      super.select{|k,_v| k!="shape_attribute_as_id"}
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
    klass.create! parent_type: self.class.name, parent_id: self.id, workbench: workbench, file: File.new(file.path), name: self.name, creator: "Web service"
  rescue Exception => e
    Chouette::Safe.capture "Import::Workbench ##{id} Child import #{file_type} creation failed", e

    failed!
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

  # Compute children status
  def children_status
    if children.unfinished.count > 0
      'running'
    elsif children.where(status: self.class.failed_statuses).count > 0
      'failed'
    elsif children.where(status: "warning").count > 0
      'warning'
    elsif children.where(status: "successful").count == children.count
      'successful'
    end
  end

  # Compute compliance_check_sets status
  def compliance_check_sets_status
    if compliance_check_sets.unfinished.count > 0
      'running'
    elsif compliance_check_sets.where(status: self.class.failed_statuses).count > 0
      'failed'
    elsif compliance_check_sets.where(status: "warning").count > 0
      'warning'
    elsif compliance_check_sets.where(status: "successful").count == compliance_check_sets.count
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
    if compliance_check_sets.present?
      if children_status == 'running' || compliance_check_sets_status == 'running'
        return 'running'
      elsif children_status == 'failed' || compliance_check_sets_status == 'failed'
        return 'failed'
      elsif children_status == 'warning' || compliance_check_sets_status == 'warning'
        return 'warning'
      elsif children_status == 'successful' && compliance_check_sets_status == 'successful'
        return 'successful'
      end
    elsif control_list_runs.present? || macro_list_runs.present?
      if children_status == 'running' || processed_status == 'running'
        return 'running'
      elsif children_status == 'failed' || processed_status == 'failed'
        return 'failed'
      elsif children_status == 'warning' || processed_status == 'warning'
        return 'warning'
      elsif children_status == 'successful' && processed_status == 'successful'
        return 'successful'
      end  
    else
      return children_status
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
    Merge.transaction do
      pending_merge = workbench.merges.order(:created_at).pending.first

      if pending_merge.present?
        pending_merge.referential_ids |= referentials.map(&:id)
        referentials.each(&:pending!)
        pending_merge.save!
      else
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
