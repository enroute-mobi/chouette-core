module Search
  class PublicationExport < Base

    # All search attributes
    attribute :status

    def candidate_statuses
      ::Operation::UserStatus.all
    end

    def query
			Query::Export.new(scope)
				.user_statuses(status)
    end

		private

		class Order < ::Search::Order
      attribute :started_at, default: :desc
    end

  end
end
