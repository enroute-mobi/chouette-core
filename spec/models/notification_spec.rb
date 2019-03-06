require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:channel){ nil }
  let(:payload){ nil }
  let(:notification){ Notification.create payload: payload, channel: channel }

  it "should delete old notifications" do
    (Notification::KEEP + 1).times{ Notification.create }
    expect(Notification.count).to eq Notification::KEEP
  end
end
