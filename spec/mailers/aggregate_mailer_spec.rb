
RSpec.describe AggregateMailer, type: :mailer do
  let(:user) {create :user}
  let(:workbench){ create :workbench }
  let(:ref1) { create :referential, workbench: workbench, organisation: workbench.organisation }
  let(:ref2) { create :referential, workbench: workbench, organisation: workbench.organisation }

  let(:aggregate) { Aggregate.create(workgroup: referential.workgroup, referentials: [ref1, ref2]) }
  let(:email) { AggregateMailer.send('finished', aggregate.id, [user.email_recipient]) }

  it 'should deliver email to user' do
    expect(email).to bcc_to user.email
  end

  it 'should have correct from' do
    expect(email.from).to eq(['chouette@example.com'])
  end

  it 'should have subject' do
    expect(email).to have_subject I18n.t('mailers.aggregate_mailer.finished.subject')
  end

  it 'should have correct body' do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    expect(email.body.raw_source.gsub("\r\n","\n")).to include I18n.t("mailers.#{aggregate.class.name.underscore}_mailer.finished.body", agg_name: aggregate.name, status: I18n.t("operation_support.statuses.#{aggregate.status}")).to_s
  end
end
