module Search
  class PublicationExport < Base
    # All search attributes
    attribute :status

    def candidate_statuses
      ::Operation::UserStatus.all
    end

    def query(scope)
      Query::Export.new(scope).user_statuses(status)
    end

    class Order < ::Search::Order
      attribute :started_at, default: :desc
    end
  end
end
