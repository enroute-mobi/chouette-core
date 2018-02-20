namespace :compliance_check_sets do
  desc "Notify parent check sets when children finish"
  task notify_parent: :environment do
    ParentNotifier.new(ComplianceCheckSet).notify_when_finished
  end

  desc "Mark old unfinished check sets as 'aborted'"
  task abort_old: :environment do
    ComplianceCheckSet.abort_old
  end
end
