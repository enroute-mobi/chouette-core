# frozen_string_literal: true

# Base class for ActiveRecord stored into a Referential
class Referential
  class ActiveRecord < Chouette::ActiveRecord
    acts_as_copy_target

    self.abstract_class = true

    class << self
      attr_reader :current_workgroup

      def current_referential
        Referential.where(slug: Apartment::Tenant.current).first!
      end
    end

    def referential
      @referential ||= self.class.current_referential
    end

    def referential_slug
      Apartment::Tenant.current
    end

    def workgroup
      self.class.current_workgroup || referential&.workgroup
    end

    delegate :prefix, to: :referential
  end
end
