module Search
	class ControlListRun < Base

		attribute :name

		def query
			Query::ControlListRun.new(scope).name(name)
		end

		class Order < ::Search::Order
			attribute :name, default: :desc
		end
	end
end
