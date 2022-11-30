module LocalExportSupport
  extend ActiveSupport::Concern

  included do |into|
    after_commit :launch_worker, on: :create
  end

  module ClassMethods
    def skip_empty_exports
      @skip_empty_exports = true
    end

    def skip_empty_exports?
      @skip_empty_exports
    end
  end

  def date_range
    return nil if duration.nil?
    @date_range ||= Time.now.to_date..self.duration.to_i.days.from_now.to_date
  end

  def export_type
    self.class.name.demodulize.underscore
  end

  def launch_worker
    if synchronous
      run unless status == "running"
    else
      enqueue_job :run
    end
  end

  def run
    update status: 'running', started_at: Time.now
    export
  rescue Exception => e
    Chouette::Safe.capture "Export ##{id} failed", e

    messages.create(criticity: :error, message_attributes: { text: e.message }, message_key: :full_text)
    self.update status: :failed, ended_at: Time.now
    raise
  end

  def export
    Chouette::Benchmark.measure "export_#{export_type}", export: id do
      referential.switch

      if self.class.skip_empty_exports && export_scope.empty?
        self.update status: :failed, ended_at: Time.now
        vals = {}
        vals[:criticity] = :info
        vals[:message_key] = :no_matching_journey
        self.messages.create vals
        return
      end

      CustomFieldsSupport.within_workgroup(referential.workgroup) do
        self.file = generate_export_file
      end

      self.status = :successful
      self.ended_at = Time.now
      self.save!
    end
  rescue => e
    Chouette::Safe.capture "#{self.class.name} ##{id} failed", e
    self.status = :failed
    self.ended_at = Time.now
    self.save!
  end

  def worker_died
    failed!

    Rails.logger.error "#{self.class.name} #{self.inspect} failed due to worker being dead"
  end
end
