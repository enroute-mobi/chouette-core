class ComplianceControlSetCopyWorker
  include Sidekiq::Worker

  def perform(control_set_id, referential_id, parent_type = nil, parent_id = nil)
    check_set = ComplianceControlSetCopier.new.copy(control_set_id, referential_id)
    check_set.update parent_type: parent_type, parent_id: parent_id if parent_type && parent_id

    if check_set.should_call_iev?
      begin
        Net::HTTP.get(URI("#{Rails.configuration.iev_url}/boiv_iev/referentials/validator/new?id=#{check_set.id}"))
      rescue Exception => e
        logger.error "IEV server error : #{e.message}"
        logger.error e.backtrace.inspect
      end
    else
      check_set.perform_internal_checks
    end
  end
end
