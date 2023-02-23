class ApplicationMailer < ActionMailer::Base
  add_template_helper MailerHelper
  include SubjectHelper
  layout 'mailer'
end
