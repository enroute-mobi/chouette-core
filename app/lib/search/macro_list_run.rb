module Search
	class MacroListRun < Base

		attribute :name

		def query
			Query::MacroListRun.new(scope).name(name)
		end

		class Order < ::Search::Order
			attribute :name, default: :desc
		end
	end
end
