RSpec.describe AggregateMailer, type: :mailer do
  let(:context) do
    Chouette.create { referential }
  end

  let(:recipient) { 'user@test.com' }
  let(:subject_prefix) { Chouette::Config.mailer.subject_prefix }
  let(:aggregate) { context.workgroup.aggregates.create!(referentials: [context.referential]) }
  subject(:email) { AggregateMailer.finished aggregate.id, recipient }

  it 'should deliver email to given email' do
    is_expected.to have_attributes(to: [recipient])
  end

  it { is_expected.to have_attributes(from: ['chouette@example.com']) }
  it { is_expected.to have_attributes(subject: [subject_prefix, I18n.t('mailers.aggregate_mailer.finished.subject')].join(' ')) }

  describe "#body" do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    subject(:body) { email.body.raw_source.gsub("\r\n","\n") }

    let(:expected_content) do
      I18n.t("mailers.aggregate_mailer.finished.body", agg_name: aggregate.name,
             status: I18n.t("operation_support.statuses.#{aggregate.status}"))
    end

    it { is_expected.to include(expected_content) }
  end
end
