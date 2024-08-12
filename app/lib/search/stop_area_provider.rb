module Search
  class StopAreaProvider < Base
    # All search attributes
    attribute :text

    def query(scope)
		  Query::StopAreaProvider.new(scope)
			  .text(text)
    end

	  private

    class Order < ::Search::Order
      attribute :name, default: :asc
    end
  end
end