module Search
	class Document < Base

		attribute :name

		def query
			Query::Document.new(scope).name(name)
		end

		class Order < ::Search::Order
      attribute :name, default: :desc
    end
	end
end
