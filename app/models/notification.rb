class Notification < ActiveRecord::Base
  KEEP=100

  before_create do
    self.payload ||= {}
    true
  end

  after_create do
    if channel.present?
      publish
    end
    Notification.order('created_at DESC').offset(KEEP).destroy_all
  end

  def publish
    # we do nothing for now
  end

  def full_payload
    payload.update({ id: id })
  end
end
