class ReferentialAudit
  class Base
    attr_reader :status

    def self.inherited klass
      ReferentialAudit::Full.register klass
    end

    def initialize referential
      @referential = referential
    end

    def faulty
      @faulty ||= @referential.switch { find_faulty }
    end

    def perform logger
      if faulty.size == 0 || faulty == [nil]
        @status = :success
      else
        logger.add_error message()
        @status = :error
      end
    end

    def name
      self.class.name
    end
  end
end

require_dependency 'referential_audit/purchase_windows_checksums'
require_dependency 'referential_audit/vehicle_journey_initial_offset'
require_dependency 'referential_audit/journey_pattern_distances'
