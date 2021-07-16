# Preview all emails at http://localhost:3000/rails/mailers/calendar_mailer
class CalendarMailerPreview < ActionMailer::Preview

  def created
    CalendarMailer.created(Calendar.first.id, User.first.id)
  end

  def updated
    CalendarMailer.updated(Calendar.first.id, User.first.id)
  end
end
