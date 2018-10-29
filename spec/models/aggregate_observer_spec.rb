require 'rails_helper'

RSpec.describe MergeObserver, type: :observer do
  let(:user) {create :user, confirmed_at: Time.now}
  let(:workbench){ create :workbench }
  let(:ref1) { create :referential, workbench: workbench, organisation: workbench.organisation }
  let(:ref2) { create :referential, workbench: workbench, organisation: workbench.organisation }

  let(:aggregate) { Aggregate.create(workgroup: referential.workgroup, referentials: [ref1, ref2], creator: user.name) }

  it 'should observe aggregate finish' do
    expect(AggregateObserver.instance).to receive(:after_update)
    aggregate.status = 'successful'
    aggregate.save
  end

  it 'should schedule mailer on aggregate finish' do
    expect(MailerJob).to receive(:perform_later).with 'AggregateMailer', 'finished', anything
    aggregate.status = 'successful'
    aggregate.save
  end
end
