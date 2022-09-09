# frozen_string_literal: true

module Delayed
  # Used to customize Delayed::Backend::ActiveRecord::Job
  module WithOrganisation
    # requires Rails 6
    # extend ActiveSupport::Concern

    def self.prepended(base)
      base.before_save :store_organisation, on: :create

      # Limit for locked/running jobs for each organisation
      base.mattr_accessor :max_workers_per_organisation, default: 1

      base.scope :in_organisation_bounds, lambda {
        # unscope to ensure it can be used as subquery
        where.not(organisation_id: all.unscope(:where, :order).out_of_bounds_organizations)
      }
      base.scope :locked, -> { where.not(locked_at: nil) }

      class << base
        prepend ClassMethods
      end
    end

    module ClassMethods
      # Overrides Delayed::Backend::ActiveRecord::Job#reserve_with_scope to ignore pending jobs
      # whose the organisation has reached the job limit
      #
      # See https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/delayed/backend/active_record.rb
      def reserve_with_scope(ready_scope, worker, now)
        super ready_scope.in_organisation_bounds, worker, now
      end

      # Returns organisation identifiers associated to more locked jobs than max_workers_per_organisation
      def out_of_bounds_organizations
        locked.group(:organisation_id).having('count(id) >= ?', max_workers_per_organisation).pluck(:organisation_id)
      end
    end

    private

    # Store the organisation identifier provided by the job
    def store_organisation
      self.organisation_id ||= payload_object.try(:organisation_id)
    end
  end
end
