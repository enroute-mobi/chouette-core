module Search
  class Entrance < Base
    extend Enumerize

    # All search attributes
    attribute :text
    attribute :stop_area_id
    attribute :zip_code
    attribute :city
    attribute :stop_area_provider
    attribute :entrance_type
    attribute :entry_flag
    attribute :exit_flag

    enumerize :entrance_type, in: ::Entrance.entrance_type.values

    attr_accessor :workbench

    def query(scope)
			Query::Entrance.new(scope)
				.text(text)
				.entrance_type(entrance_type)
				.stop_area_id(stop_area_id)
				.zip_code(zip_code)
				.city_name(city)
				.stop_area_provider_id(stop_area_provider)
				.entry_flag(entry_flag)
				.exit_flag(exit_flag)
    end

    def entry_flag
      flag(super)
    end

    def exit_flag
      flag(super)
    end

    def candidate_stop_areas
      workbench.stop_area_referential.stop_areas.limit(50)
    end

    def stop_area_provider_options
      workbench.stop_area_referential.stop_area_providers.pluck(:name, :id)
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
