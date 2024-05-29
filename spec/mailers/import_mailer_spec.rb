RSpec.describe ImportMailer, type: :mailer do
  let(:context) do
    Chouette.create { workbench }
  end

  let(:recipient) { 'user@test.com' }
  let(:import) do
    Import::Workbench.create!(name: "test", creator: "test",
                              workbench: context.workbench,
                              file: open_fixture('google-sample-feed.zip'))
  end
  subject(:email) { ImportMailer.finished(import.id, recipient) }

  it 'should deliver email to given email' do
    is_expected.to have_attributes(to: [recipient])
  end

  it { is_expected.to have_attributes(from: ['chouette@example.com']) }

  describe "#body" do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    subject(:body) { email.body.raw_source.gsub("\r\n","\n") }

    let(:expected_content) do
      I18n.t("mailers.import_mailer.finished.body", import_name: import.name,
             status: I18n.t("mailers.statuses.#{import.status}"))
    end

    it { is_expected.to include(expected_content) }
  end
end
