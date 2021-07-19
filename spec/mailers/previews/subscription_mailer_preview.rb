# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview

  def created
    SubscriptionMailer.created(User.first.id)
  end

end
