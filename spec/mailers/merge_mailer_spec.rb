RSpec.describe MergeMailer, type: :mailer do
  let(:context) do
    Chouette.create { referential }
  end

  let(:recipient) { 'user@test.com' }
  let(:merge) { context.workbench.merges.create!(referentials: [context.referential]) }
  subject(:email) { MergeMailer.finished(merge.id, recipient) }

  it 'should deliver email to given email' do
    is_expected.to have_attributes(to: [recipient])
  end

  it { is_expected.to have_attributes(from: ['chouette@example.com']) }

  describe "#body" do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    subject(:body) { email.body.raw_source.gsub("\r\n","\n") }

    let(:expected_content) do
      I18n.t("mailers.merge_mailer.finished.body", merge_name: merge.name,
             status: I18n.t("mailers.statuses.#{merge.status}"))
    end

    it { is_expected.to include(expected_content) }
  end
end
