module Chouette
  class TridentActiveRecord < Chouette::ActiveRecord
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

    def hub_restricted?
      referential.data_format == "hub"
    end

    def prefix
      referential.prefix
    end

  end
end
