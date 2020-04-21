module LocalExportSupport
  extend ActiveSupport::Concern

  included do |into|
    include ImportResourcesSupport
    after_commit :launch_worker, on: :create
  end

  module ClassMethods
    attr_accessor :skip_empty_exports
  end

  def launch_worker
    if synchronous
      run unless status == "running"
    else
      enqueue_job :run
    end
  end

  def date_range
    return nil if duration.nil?
    @date_range ||= Time.now.to_date..self.duration.to_i.days.from_now.to_date
  end

  def journeys
    @journeys ||= Chouette::VehicleJourney.with_matching_timetable (date_range)
  end

  def export
    referential.switch

    if self.class.skip_empty_exports && journeys.count == 0
      self.update status: :failed, ended_at: Time.now
      vals = {}
      vals[:criticity] = :info
      vals[:message_key] = :no_matching_journey
      self.messages.create vals
      return
    end

    upload_file generate_export_file
    self.status = :successful
    self.ended_at = Time.now
    self.save!
  rescue => e
    Rails.logger.info "Failed: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
    self.status = :failed
    self.save!
  end

  def worker_died
    failed!

    Rails.logger.error "#{self.class.name} #{self.inspect} failed due to worker being dead"
  end
end
