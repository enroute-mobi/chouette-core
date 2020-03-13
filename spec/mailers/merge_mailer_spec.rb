
RSpec.describe MergeMailer, type: :mailer do
  let(:user) {create :user}
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential) { create :referential, workbench: workbench, organisation: workbench.organisation }
  let(:referential_metadata){ create(:referential_metadata, lines: line_referential.lines.limit(3), referential: referential) }

  let(:merge) { Merge.create(workbench: referential.workbench, referentials: [referential, referential]) }
  let(:email)    { MergeMailer.send('finished', merge.id, [user.email_recipient]) }

  it 'should deliver email to user' do
    expect(email).to bcc_to user.email
  end

  it 'should have correct from' do
    expect(email.from).to eq(['chouette@example.com'])
  end

  it 'should have subject' do
    expect(email).to have_subject I18n.t("mailers.merge_mailer.finished.subject")
  end

  it 'should have correct body' do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    expect(email.body.raw_source.gsub("\r\n","\n")).to include I18n.t("mailers.merge_mailer.finished.body", merge_name: merge.name, status: I18n.t("operation_support.statuses.#{merge.status}"))
  end
end
