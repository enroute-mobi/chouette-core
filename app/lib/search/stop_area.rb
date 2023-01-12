module Search
  class StopArea < Base
		extend Enumerize

    # All search attributes
    attribute :name
    attribute :zip_code
    attribute :city_name
    attribute :area_type
    attribute :statuses
    attribute :is_referent
    attribute :parent
    attribute :stop_area_provider

		enumerize :area_type, in: ::Chouette::AreaType::ALL
		enumerize :statuses, in: ::Chouette::StopArea.statuses, multiple: true

    def query
			Query::StopArea.new(scope)
				.name(name)
				.zip_code(zip_code)
				.city_name(city_name)
				.area_type(area_type)
				.statuses(statuses)
				.is_referent(is_referent)
				.parent(parent)
				.stop_area_provider(stop_area_provider)
    end

		def is_referent
			flag(super)
		end

		def stop_area_provider_options
			StopAreaProvider.where(id: scope.pluck(:stop_area_provider_id)).pluck(:name, :id)
		end

		private

		def flag(value)
			ActiveModel::Type::Boolean.new.cast(value)
		end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
