class Import::Resource < ApplicationModel
  self.table_name = :import_resources

  include IevInterfaces::Resource

  belongs_to :import, class_name: 'Import::Base'
  belongs_to :referential
  has_many :messages, class_name: 'Import::Message', foreign_key: :resource_id, dependent: :delete_all

  scope :main_resources, ->{ where(resource_type: "referential") }

  def root_import
    import = self.import
    import = import.parent while import.parent
    import
  end

  def next_step
    Rails.logger.info "#{self.class.name} ##{child_import.id}: next_step"

    if root_import.class == Import::Workbench

      return unless child_import&.successful? || child_import&.warning?

      # We should not execute compliance_check_set if referential doesn't exist
      # It's useful for partial netex generic import (Stop area, Line,....)
      return unless referential_id.present?

      Rails.logger.info "Import ##{child_import.id}: Create import_compliance_control_sets"
      workbench.workgroup.import_compliance_control_sets.map do |key, label|
        next unless (control_set = workbench.compliance_control_set(key)).present?
        compliance_check_set = workbench_import_check_set key
        if compliance_check_set.nil?
          ComplianceControlSetCopier.new.copy control_set.id, referential_id, nil, root_import.class.name, root_import.id, key
        end
      end
    end
  end

  def workbench
    import.workbench
  end

  def workgroup
    workbench.workgroup
  end

  def child_import
    return unless self.resource_type == "referential"
    import.children.where(name: self.reference).last
  end

  def workbench_import_check_set key
    return unless referential.present?
    control_set = referential.workbench.compliance_control_set(key)
    return unless control_set.present?
    referential.compliance_check_sets.where(compliance_control_set_id: control_set.id, referential_id: referential_id).last
  end
end
