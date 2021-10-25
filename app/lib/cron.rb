module Cron
  class << self
    def method_missing method_name, *args, &block
      if method_name =~ /every_*/
        if args.count > 0 || block_given?
          # we want to set actions
          @actions ||= Hash.new { |hash, key| hash[key] = [] }
          time_code = normalize_time_code method_name
          @actions[time_code] += args
          @actions[time_code] << block if block_given?
        else
          # we want to run actions
          run_actions method_name
        end
      else
        super method_name, *args
      end
    end

    def run_actions time_code
      Rails.logger.info "Cron.#{time_code}"
      @actions ||= {}
      actions = @actions[normalize_time_code(time_code)] || []
      actions.each &method(:run_action)
    end

    def run_action action
      protected_action do
        if action.is_a? Proc
          action.call
        elsif self.respond_to? action, true
          self.send action
        end
      end
    end

    def print
      @actions ||= {}
      @actions.sort.each do |time_code, actions|
        puts "#{time_code}: "
        actions.each do |action|
          if action.is_a? Proc
            puts "  - Proc (#{action.source_location.join(':')})"
          elsif self.respond_to? action, true
            puts "  - #{action}"
          end
        end
      end
      nil
    end

    private

    def normalize_time_code name
      name.to_s.downcase.intern
    end

    def protected_action
      begin
        yield
      rescue => e
        Chouette::Safe.capture "Cron action failed", e
      end
    end

    def check_nightly_aggregates
      protected_action do
        Workgroup.where(nightly_aggregate_enabled: true).each(&:nightly_aggregate!)
      end
    end

    def check_ccset_operations
      protected_action do
        # ParentNotifier.new(ComplianceCheckSet).notify_when_finished
        ComplianceCheckSet.abort_old
      end
    end

    def check_import_operations
      protected_action do
        ParentNotifier.new(Import::Base).notify_when_finished
        Import::Netex.abort_old
      end
    end

    def audit_referentials
      protected_action do
        AuditMailer.audit_if_enabled
      end
    end

    def handle_dead_workers
      protected_action do
        Delayed::Heartbeat::Worker.handle_dead_workers
      end
    end

    def purge_referentials
      protected_action do
        Workbench.find_each do |w|
          w.referentials.clean!
        end
      end
    end

    def purge_workgroups
      protected_action do
        Workgroup.purge_all
      end
    end

    def retrieve_all_sources
      protected_action do
        Source.retrieve_all
      end
    end

  end
end
