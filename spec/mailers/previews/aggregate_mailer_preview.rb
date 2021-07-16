# Preview all emails at http://localhost:3000/rails/mailers/calendar_mailer
class AggregateMailerPreview < ActionMailer::Preview

  def finished
    AggregateMailer.finished(Aggregate.first.id, User.first.email)
  end

end