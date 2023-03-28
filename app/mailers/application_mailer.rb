class ApplicationMailer < ActionMailer::Base
  add_template_helper MailerHelper
  layout 'mailer'
  include MailerHelper
end
