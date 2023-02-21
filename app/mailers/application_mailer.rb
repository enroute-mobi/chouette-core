class ApplicationMailer < ActionMailer::Base
  add_template_helper MailerHelper
  layout 'mailer'

  def subject_prefix
    Chouette::Config.mailer.subject_prefix
  end

  def mail_subject(subject, options={})
    #subject_translated = !options[:translate] ? subject : t(subject, options)
    subject_translated = t(subject, options)
    [ subject_prefix, subject_translated ].compact.join(' ')
  end
end
