# frozen_string_literal: true

# Notification mail sent when a scheduled Macro::List::Run is done.
# See ProcessingRule::Scheduling and the Operation::Notifier callback.
class MacroListRunMailer < ApplicationMailer
  def finished(macro_list_run_id, recipient, status = nil)
    @macro_list_run = Macro::List::Run.find(macro_list_run_id)
    @status = status || @macro_list_run.user_status
    mail to: recipient, subject: mail_subject
  end
end
