require 'rails_helper'

RSpec.describe ExportObserver, type: :observer do
  let(:user) { create :user, confirmed_at: Time.now }
  let(:parent) { create(:workbench_import, creator: user.name) }
  let(:referential) { create :referential }
  let(:export) { create(:gtfs_export, creator: user.name) }

  it 'should observe export create' do
    expect(ExportObserver.instance).to receive(:after_update)
    export.status = 'successful'
    export.save
  end

  it 'should schedule mailer on import create' do
    expect(MailerJob).to receive(:perform_later).with 'ExportMailer', 'finished', anything
    export.status = 'successful'
    export.save
  end
end
