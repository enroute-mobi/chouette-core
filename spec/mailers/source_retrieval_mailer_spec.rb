# frozen_string_literal: true

RSpec.describe SourceRetrievalMailer, type: :mailer do
  subject(:email) { SourceRetrievalMailer.finished(retrieval.id, recipient) }

  let(:context) { Chouette.create { source } }
  let(:recipient) { 'user@test.com' }
  let(:source) { context.source }
  let(:retrieval) do
    source.retrievals.create!(creator: 'Source', user_status: :successful)
  end

  it 'should deliver email to given email' do
    is_expected.to have_attributes(to: [recipient])
  end

  it { is_expected.to have_attributes(from: ['chouette@example.com']) }

  describe '#body' do
    # With Rails 4.2.11 upgrade, email body contains \r\n. See #9423
    subject(:body) { email.body.raw_source.gsub("\r\n", "\n") }

    let(:expected_content) do
      I18n.t('mailers.source_retrieval_mailer.finished.body', source_name: source.name, status: I18n.t("mailers.statuses.successful"))
    end

    it { is_expected.to include(expected_content) }
  end
end
