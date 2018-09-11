module IevInterfaces::Resource
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :status, in: %i(OK ERROR WARNING IGNORED), scope: true
    validates_presence_of :name, :resource_type
  end

  def update_status_from_importer importer_status
    self.update status: status_from_importer(importer_status)
  end

  def update_status_from_messages
    self.update status: status_from_messages
  end

  def status_from_messages
    status = if messages.where(criticity: :error).exists?
      :ERROR
    elsif messages.where(criticity: :warning).exists?
      :WARNING
    else
      :OK
    end
  end

  def status_from_importer importer_status
    return nil unless importer_status.present?
    {
      new: nil,
      pending: nil,
      successful: :OK,
      warning: :WARNING,
      failed: :ERROR,
      running: nil,
      aborted: :ERROR,
      canceled: :ERROR
    }[importer_status.to_sym]
  end
end
