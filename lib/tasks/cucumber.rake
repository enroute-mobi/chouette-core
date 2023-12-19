# frozen_string_literal: true

namespace :cucumber do
  desc 'Remove all test organisations created by cucumber'
  task clean: [:environment] do |_task|
    Cleaner.new.load_env.clean
  end

  class Cleaner
    def initialize
      self.delay = 2.hours
      self.dry_run = false
    end

    attr_accessor :delay, :dry_run, :keep_count

    def load_env
      self.delay = env('DELAY').hours if env('DELAY')
      self.keep_count = env('KEEP_COUNT')&.to_i
      self.dry_run = (env('DRY_RUN') == 'true')

      self
    end

    def env(name)
      ENV["CHOUETTE_CLEAN_TEST_ORGANISATIONS_#{name}"]
    end

    def organisations
      organisations =
        Organisation.joins(:users)
                    .where("users.email like 'test+%@chouette.test'").distinct

      organisations = organisations.where('organisations.created_at < ?', Time.zone.now - delay) if delay
      organisations = organisations.offset(keep_count) if keep_count

      organisations
    end

    def clean
      puts "Remove #{organisations.count} test organisation(s)"

      organisations.find_each do |organisation|
        if dry_run
          puts "Destroy Organisation '#{organisation.name}' ##{organisation.id}"
        else
          Organisation.transaction do
            organisation.workgroups.owned.each(&:destroy!)
            organisation.destroy!
          rescue StandardError => e
            message = "Can't clean test organisation ##{organisation.id}"
            puts message
            Chouette::Safe.capture message, e
          end
        end
      end
    end
  end
end
