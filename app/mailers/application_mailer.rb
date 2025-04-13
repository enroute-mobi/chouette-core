# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  helper MailerHelper
  layout 'mailer'
  include MailerHelper
end
