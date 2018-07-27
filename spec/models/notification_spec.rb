require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:channel){ nil }
  let(:payload){ nil }
  let(:notification){ Notification.create payload: payload, channel: channel }
  let!(:publication_request){
    stub_request(
      :post,
      "#{Rails.application.config.rails_host}/faye"
    )
  }
  it "should set an objectid" do
    expect(notification.objectid).to be_present
  end

  it "should not publish event" do
    notification
    expect(publication_request).to_not have_been_requested
  end

  context "with a channel" do
    let(:channel){ "channel" }

    it "should publish event" do
      notification
      expect(publication_request).to have_been_requested
    end
  end

  it "should delete old notifications" do
    (Notification::KEEP + 1).times{ Notification.create }
    expect(Notification.count).to eq Notification::KEEP
  end
end
