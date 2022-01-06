RSpec.describe ComplianceCheckSetMailer, type: :mailer do
  let(:context) do
    Chouette.create { referential }
  end

  let(:recipient) { 'user@test.com' }
  let(:operation) do
    context.workbench.compliance_check_sets.create!(
      workgroup: context.workgroup,
      referential: context.referential
    )
  end
  subject(:email) { ComplianceCheckSetMailer.finished(operation.id, recipient) }

  it 'should deliver email to given email' do
    is_expected.to have_attributes(to: [recipient])
  end

  it { is_expected.to have_attributes(from: ['chouette@example.com']) }
  it { is_expected.to have_attributes(subject: I18n.t('mailers.compliance_check_set_mailer.finished.subject')) }

  describe "#body" do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    subject(:body) { email.body.raw_source.gsub("\r\n","\n") }

    let(:expected_content) do
      I18n.t("mailers.compliance_check_set_mailer.finished.body",
             ref_name: operation.referential.name,
             status: I18n.t("operation_support.statuses.#{operation.status}"))
    end

    it { is_expected.to include(expected_content) }
  end
end
