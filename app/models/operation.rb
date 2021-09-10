class Operation
  class UserStatus
    def initialize(slug, operation_statuses = nil)
      operation_statuses ||= [ slug ]
      @slug, @operation_statuses = slug.to_sym, operation_statuses.map(&:to_sym)

      operation_statuses.freeze
      freeze
    end

    attr_reader :slug, :operation_statuses

    def self.all
      ALL
    end

    alias to_sym slug

    def to_s
      slug.to_s
    end

    def self.find(*slugs)
      slugs = slugs.flatten.map(&:to_sym)
      all.select { |user_status| slugs.include? user_status.slug }
    end

    PENDING = new 'pending', %w[new pending running]
    FAILED = new 'failed', %w[failed aborted canceled]
    WARNING = new 'warning'
    SUCCESSFUL = new 'successful'

    ALL = [ PENDING, SUCCESSFUL, WARNING, FAILED ].freeze
  end
end
