class ComplianceCheckSetWorker
  include Sidekiq::Worker
  include Concerns::LongRunningWorker

  def perform(check_set_id, only_internals=false)
    check_set = ComplianceCheckSet.find(check_set_id)
    begin
      check_set.perform only_internals
    rescue
      check_set.failed!
    end
  end
end
