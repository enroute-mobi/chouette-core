RSpec.describe ExportMailer, type: :mailer do
  let(:context) do
    Chouette.create { referential }
  end

  let(:recipient) { 'user@test.com' }
  let(:export) do
    Export::Gtfs.create!(name: "Test", creator: 'test',
                         referential: context.referential,
                         workgroup: context.workgroup,
                         workbench: context.workbench)
  end
  subject(:email) { ExportMailer.finished(export.id, recipient) }

  it 'should deliver email to given email' do
    is_expected.to have_attributes(to: [recipient])
  end

  it { is_expected.to have_attributes(from: ['chouette@example.com']) }


  describe "#body" do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    subject(:body) { email.body.raw_source.gsub("\r\n","\n") }

    let(:expected_content) do
      I18n.t("mailers.export_mailer.finished.body", export_name: export.name,
             status: I18n.t("mailers.statuses.#{export.status}"))
    end

    it { is_expected.to include(expected_content) }
  end
end
