# frozen_string_literal: true

# Notification mail sent when a scheduled Control::List::Run is done.
# See ProcessingRule::Scheduling and the Operation::Notifier callback.
class ControlListRunMailer < ApplicationMailer
  def finished(control_list_run_id, recipient, status = nil)
    @control_list_run = Control::List::Run.find(control_list_run_id)
    @status = status || @control_list_run.user_status
    mail to: recipient, subject: mail_subject
  end
end
