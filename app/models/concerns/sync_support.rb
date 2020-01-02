module SyncSupport
  extend ActiveSupport::Concern

  included do
    after_create :clean_previous_syncs
    @keep_syncs = 40

    class << self
      attr_accessor :keep_syncs
    end
  end

  def clean_previous_syncs
    return unless clean_scope && clean_scope.count > self.class.keep_syncs
    while clean_scope.count > self.class.keep_syncs do
      clean_scope.reorder("created_at asc").first.destroy
    end
  end

  def clean_scope
    referential&.send(self.class.name.tableize)
  end

  def worker_died
    failed({
      error: "Worker has been killed"
    })

    Rails.logger.error "#{self.class.name} #{self.inspect} failed due to worker being dead"
  end
end
