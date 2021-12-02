module Search
  class Entrance < Base
		extend Enumerize
	
    # All search attributes
    attribute :name
    attribute :stop_area
    attribute :zip_code
    attribute :city
    attribute :stop_area_provider
    attribute :entrance_type
    attribute :entry_flag
    attribute :exit_flag

		enumerize :entrance_type, in: ::Entrance.entrance_type.values

    def query
			Query::Entrance.new(scope)
				.where(name, :matches, :name, :short_name)
				.where(entrance_type, :in, :entrance_type)
				.where(stop_area, :eq, :stop_area_id)
				.where(zip_code, :matches, :zip_code)
				.where(city, :matches, :city_name)
				.where(stop_area_provider, :eq, :stop_area_provider_id)
				.where(entry_flag, :in, :entry_flag)
				.where(exit_flag, :in, :exit_flag)
    end

		def entry_flag
			flag(super)
		end

		def exit_flag
			flag(super)
		end

		def stop_area_options
			Chouette::StopArea.where(id: scope.pluck(:stop_area_id)).pluck(:name, :id)
		end

		def stop_area_provider_options
			StopAreaProvider.where(id: scope.pluck(:stop_area_provider_id)).pluck(:name, :id)
		end

		private

		def flag(value)
			(value || [])
				.map { |v| ActiveModel::Type::Boolean.new.cast(v) }
				.compact
		end

    class Order < ::Search::Order
      attribute :name, default: :desc
    end
  end
end


