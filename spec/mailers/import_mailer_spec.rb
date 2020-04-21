
RSpec.describe ImportMailer, type: :mailer do

  let(:user) { create(:user) }
  let(:referential) {create :referential}
  let(:import) {create :gtfs_import, referential: referential, parent: create(:workbench_import, creator: user.name)}
  let(:email)    { ImportMailer.send('finished', import.id, [user.email_recipient]) }

  it 'should deliver email to user' do
    expect(email).to bcc_to user.email
  end

  it 'should have correct from' do
    expect(email.from).to eq(['chouette@example.com'])
  end

  it 'should have subject' do
    expect(email).to have_subject I18n.t('mailers.import_mailer.finished.subject')
  end

  it 'should have correct body' do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    expect(email.body.raw_source.gsub("\r\n","\n")).to include I18n.t("mailers.import_mailer.finished.body", import_name: import.name, status: I18n.t("operation_support.statuses.#{import.status}"))
  end
end
