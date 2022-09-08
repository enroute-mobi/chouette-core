# frozen_string_literal: true

module Delayed
  # Used to customize Delayed::Backend::ActiveRecord::Job
  module WithOrganisation
    extend ActiveSupport::Concern

    included do
      before_save :store_organisation, on: :create

      # Limit for locked/running jobs for each organisation
      mattr_accessor :max_workers_per_organisation, default: 1

      scope :in_organisation_bounds, -> { where.not(organisation_id: out_of_bounds_organizations) }
      scope :locked, -> { where.not(locked_at: nil) }
    end

    class_methods do
      # Overrides Delayed::Backend::ActiveRecord::Job#reserve_with_scope to ignore pending jobs
      # whose the organisation has reached the job limit
      #
      # See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
      def reserve_with_scope(ready_scope, worker, now)
        Rails.logger.debug { 'reserve_with_scope with organisation limit' }
        super ready_scope.in_organisation_bounds, worker, now
      end

      # Returns organisation identifiers associated to more locked jobs than max_workers_per_organisation
      def out_of_bounds_organizations
        locked.select(:organisation_id).group(:organisation_id).having('count(id) >= ?', max_workers_per_organisation)
      end
    end

    # Store the organisation identifier provided by the job
    def store_organisation
      self.organisation_id = payload_object.try(:organisation_id)
    end
  end
end
