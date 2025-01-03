class ReferentialCloning < ApplicationModel
  include AASM
  belongs_to :source_referential, class_name: 'Referential' # TODO: CHOUETTE-3247 optional: true?
  belongs_to :target_referential, class_name: 'Referential' # TODO: CHOUETTE-3247 optional: true?
  after_commit :clone, on: :create

  def clone
    enqueue_job :clone_with_status!
  end

  def clone_with_status!
    run!
    clone!
    successful!
  rescue Exception => e
    Chouette::Safe.capture "Clone ##{id} failed", e
    failed!
  end

  def worker_died
    failed!

    Rails.logger.error "#{self.class.name} #{self.inspect} failed due to worker being dead"
  end

  def clone!
    Chouette::Benchmark.measure("referential.clone", source: source_referential.id, target: target_referential.id) do
      source_referential.schema.clone_to(target_referential.schema)
    end
    clean
  end

  def clean
    CleanUp.new(referential: target_referential).clean
  end

  private

  aasm column: :status do
    state :new, :initial => true
    state :pending
    state :successful
    state :failed

    event :run, after: :update_started_at do
      transitions :from => [:new, :failed], :to => :pending
    end

    event :successful, after: :update_ended_at do
      after do
        target_referential.update_attribute(:ready, true)
        target_referential.rebuild_cross_referential_index!
      end
      transitions :from => [:pending, :failed], :to => :successful
    end

    event :failed, after: :update_ended_at do
      transitions :from => [:new, :pending], :to => :failed
      after do
        target_referential&.failed!
      end
    end
  end

  def update_started_at
    update_attribute(:started_at, Time.now)
  end

  def update_ended_at
    update_attribute(:ended_at, Time.now)
  end
end
