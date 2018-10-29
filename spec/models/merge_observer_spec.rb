require 'rails_helper'

RSpec.describe MergeObserver, type: :observer do
  let(:user) { create :user, confirmed_at: Time.now }
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential) { create :referential, workbench: workbench, organisation: workbench.organisation }
  let(:referential_metadata){ create(:referential_metadata, lines: line_referential.lines.limit(3), referential: referential) }

  let(:merge) { Merge.create(workbench: referential.workbench, referentials: [referential, referential], creator: user.name) }

  it 'should observe merge finish' do
    expect(MergeObserver.instance).to receive(:after_update)
    merge.status = 'successful'
    merge.save
  end

  it 'should schedule mailer on merge finish' do
    expect(MailerJob).to receive(:perform_later).with 'MergeMailer', 'finished', anything
    merge.status = 'successful'
    merge.save
  end
end
