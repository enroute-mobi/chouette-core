module Search
  class StopArea < Base
		extend Enumerize

    # All search attributes
    attribute :name
    attribute :zip_code
    attribute :city_name
    attribute :area_type
    attribute :status
    attribute :is_referent
    attribute :parent
    attribute :stop_area_provider

		enumerize :area_type, in: Chouette::AreaType::ALL
		enumerize :status, in: %i[in_creation confirmed deactivated]

    def query
			Query::StopArea.new(scope)
				.name(name)
				.zip_code(zip_code)
				.city_name(city_name)
				.area_type(area_type)
				.status(status)
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
			(value || [])
				.map { |v| ActiveModel::Type::Boolean.new.cast(value) }
				.compact
		end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end
