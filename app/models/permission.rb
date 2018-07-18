class Permission

  def self.edit
    # FIXME
    Stif::PermissionTranslator.translate(["boiv:edit-offer"])
  end

  def self.base
    permissions = edit

    %w{purchase_windows exports}.each do |resources|
      actions = %w{edit update create destroy}
      actions.each do |action|
        permissions << "#{resources}.#{action}"
      end
    end

    permissions << "calendars.share"
  end

  def self.referentials
    permissions = []
    %w{stop_areas stop_area_providers lines companies networks}.each do |resources|
      actions = %w{edit update create}
      actions << (%w{stop_areas lines}.include?(resources) ? "change_status" : "destroy")

      actions.each do |action|
        permissions << "#{resources}.#{action}"
      end
    end
    permissions
  end

  def self.all
    base + referentials
  end

end
