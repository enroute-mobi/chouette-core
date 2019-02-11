module LocalExportSupport
  extend ActiveSupport::Concern

  included do |into|
    include ImportResourcesSupport
    after_commit :launch_worker, on: :create
  end

  def launch_worker
    if synchronous
      run unless status == "running"
    else
      worker_class.perform_async_or_fail(self)
    end
  end

  def zip_file_name
    @zip_file_name ||= "chouette-its-#{Time.now.to_i}"
  end

  def date_range
    @date_range ||= Time.now.to_date..self.duration.to_i.days.from_now.to_date
  end

  def journeys
    @journeys ||= Chouette::VehicleJourney.with_matching_timetable (date_range)
  end

  def export
    referential.switch

    if journeys.count == 0
      self.update status: :successful, ended_at: Time.now
      vals = {}
      vals[:criticity] = :info
      vals[:message_key] = :no_matching_journey
      self.messages.create vals
      return
    end

    generate_export_file
    self.status = :successful
    self.ended_at = Time.now
    self.save!
  rescue => e
    Rails.logger.info "Failed: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
    self.status = :failed
    self.save!
  end
end
