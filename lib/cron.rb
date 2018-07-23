module Cron
  class << self

    def every_day_at_3AM
      sync_reflex
      get_missing_routes_costs
    end

    def every_day_at_4AM
      sync_codifligne
    end

    def every_hour
      sync_organizations
      sync_users
    end

    def every_5_minutes
      Rails.logger.info "Cron.every_5_minutes"
      check_import_operations
      check_ccset_operations
    end

    private

    def sync_organizations
      begin
        Organisation.portail_sync
      rescue => e
        Rails.logger.error(e.inspect)
      end
    end

    def sync_users
      begin
        User.portail_sync
      rescue => e
        Rails.logger.error(e.inspect)
      end
    end

    def sync_reflex
      begin
        sync = StopAreaReferential.find_by(name: 'Reflex').stop_area_referential_syncs.build
        raise "reflex:sync aborted - There is already an synchronisation in progress" unless sync.valid?
        sync.save
      rescue => e
        Rails.logger.warn(e.message)
      end
    end

    def sync_codifligne
      begin
        sync = LineReferential.find_by(name: 'CodifLigne').line_referential_syncs.build
        raise "Codifligne:sync aborted - There is already an synchronisation in progress" unless sync.valid?
        sync.save
      rescue => e
        Rails.logger.warn(e.message)
      end
    end

    def check_ccset_operations
      begin
        ParentNotifier.new(ComplianceCheckSet).notify_when_finished
        ComplianceCheckSet.abort_old
      rescue => e
        Rails.logger.error(e.inspect)
      end
    end

    def check_import_operations
      begin
        ParentNotifier.new(Import::Base).notify_when_finished
        Import::Netex.abort_old
      rescue => e
        Rails.logger.error(e.inspect)
      end
    end

    def get_missing_routes_costs
      begin
        Rails.logger.info "Getting missing routes costs from TomTom"
        referentials = Referential.not_in_referential_suite
        referentials += Workbench.all.map { |w| w.output.current }.compact
        remaining = 1000 #we process only 1000 routes a day
        referentials.sort_by(&:created_at).reverse.each do |referential|
          break if remaining == 0
          referential.switch do
            Rails.logger.info "\n \e[33m***\e[0m Referential #{referential.name}"
            missing_costs =  Chouette::Route.where(costs: nil).limit(remaining)
            Rails.logger.info "found #{missing_costs.count} Routes with no costs"
            remaining -= missing_costs.count
            missing_costs.each &:calculate_costs
            Rails.logger.info "remaining credits: #{remaining}"
          end
        end
      rescue => e
        Rails.logger.error(e.inspect)
      end
    end
  end
end
