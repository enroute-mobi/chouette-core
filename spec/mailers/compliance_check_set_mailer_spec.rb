
RSpec.describe ComplianceCheckSetMailer, type: :mailer do
  let(:user) {create :user}

  let(:ccset) { create :compliance_check_set, metadata: {creator_id: user.id} }
  let(:email)    { ComplianceCheckSetMailer.send('finished', ccset.id, [user.email_recipient]) }

  it 'should deliver email to user' do
    expect(email).to bcc_to user.email
  end

  it 'should have correct from' do
    expect(email.from).to eq(['chouette@example.com'])
  end

  it 'should have subject' do
    expect(email).to have_subject I18n.t("mailers.compliance_check_set_mailer.finished.subject")
  end

  it 'should have correct body' do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    expect(email.body.raw_source.gsub("\r\n","\n")).to include I18n.t("mailers.compliance_check_set_mailer.finished.body", ref_name: ccset.referential.name, status: I18n.t("operation_support.statuses.#{ccset.status}"))
  end
end
