class ReferentialAudit
  class Base
    attr_reader :status

    def self.inherited klass
      ReferentialAudit::FullReferential.register klass
    end

    def initialize referential
      @referential = referential
    end

    def faulty
      @faulty ||= @referential.switch { find_faulty }
    end

    def perform logger
      faulty.each do |record|
        logger.add_error full_message(record)
      end
      if faulty.size == 0 || faulty == [nil]
        @status = :success
      else
        @status = :error
      end
    end

    def full_message record
      message(record)
    end

    def self.pretty_name
      self.name.split("::").last
    end

    def pretty_name
      self.class.pretty_name
    end
  end
end

require_dependency 'referential_audit/purchase_windows_checksums'
require_dependency 'referential_audit/vehicle_journey_initial_offset'
require_dependency 'referential_audit/journey_pattern_distances'
require_dependency 'referential_audit/checksums'
