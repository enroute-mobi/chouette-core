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
    Thread.new do
      uri = URI.parse "#{Rails.application.config.rails_host}/faye"
      Net::HTTP.post_form(uri, { message: { data: payload, channel: channel}.to_json })
    end
  end
end
