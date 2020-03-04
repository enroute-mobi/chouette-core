class ReferentialCloning < ApplicationModel
  include AASM
  belongs_to :source_referential, class_name: 'Referential'
  belongs_to :target_referential, class_name: 'Referential'
  after_commit :clone, on: :create

  def clone
    enqueue_job :clone_with_status!
  end

  def clone_with_status!
    run!
    clone!
    successful!
  rescue Exception => e
    Rails.logger.error "Clone failed : #{e}"
    Rails.logger.error e.backtrace.join('\n')
    failed!
  end

  def worker_died
    failed!

    Rails.logger.error "#{self.class.name} #{self.inspect} failed due to worker being dead"
  end

  def clone!
    report = Benchmark.measure do
      command = "#{dump_command} | #{sed_command} | #{restore_command}"
      unless system command
        raise "Copy of #{source_schema} to #{target_schema} failed"
      end
    end
    target_referential.check_migration_count(report)
    clean
  end

  def source_schema
    source_referential.slug
  end

  def target_schema
    target_referential.slug
  end

  def host
    ActiveRecord::Base.connection_config[:host]
  end

  def port
    ActiveRecord::Base.connection_config[:port] || 5432
  end

  def username
    ActiveRecord::Base.connection_config[:username]
  end

  def password
    ActiveRecord::Base.connection_config[:password]
  end

  def database
    ActiveRecord::Base.connection_config[:database]
  end

  def dump_command
    "PGPASSWORD='#{password}' pg_dump --host #{host} --port #{port} --username #{username} --schema=#{source_schema} #{database}"
  end

  def sed_command
    "sed -e 's@#{source_schema}@#{target_schema}@g'"
  end

  def restore_command
    "PGPASSWORD='#{password}' psql -q --host #{host} --port #{port} --username #{username} #{database}"
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
