# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SourceRetrievalMailerPreview < ActionMailer::Preview
  def finished
    SourceRetrievalMailer.finished(Source::Retrieval.first.id, 'toto@enroute.mobi')
  end
end
