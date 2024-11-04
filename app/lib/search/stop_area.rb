# frozen_string_literal: true

module Search
  class StopArea < Base
    extend Enumerize

    # All search attributes
    attribute :text
    attribute :zip_code
    attribute :city_name
    attribute :area_type
    attribute :statuses
    attribute :is_referent
    attribute :parent_id
    attribute :stop_area_provider_id

    enumerize :area_type, in: ::Chouette::AreaType::ALL
    enumerize :statuses, in: ::Chouette::StopArea.statuses, multiple: true, i18n_scope: 'stop_areas.statuses'

    validates :parent_stop_area,
              inclusion: { in: ->(search) { search.candidate_parents } },
              allow_blank: true, allow_nil: true

    attr_accessor :workbench

    delegate :stop_area_referential, to: :workbench

    def searched_class
      ::Chouette::StopArea
    end

    def query(scope)
      Query::StopArea.new(scope)
                     .text(text)
                     .zip_code(zip_code)
                     .city_name(city_name)
                     .area_type(area_type)
                     .statuses(statuses)
                     .is_referent(is_referent)
                     .parent_id(parent_id)
                     .stop_area_provider_id(stop_area_provider_id)
    end

    def is_referent # rubocop:disable Naming/PredicateName
      flag(super)
    end

    def candidate_stop_area_providers
      stop_area_referential.stop_area_providers
    end

    def candidate_parents
      stop_area_referential&.stop_areas
    end

    def selected_parent_collection
      [parent_stop_area].compact
    end

    def parent_stop_area
      stop_area_referential.stop_areas.find(parent_id) if parent_id.present?
    end

    private

    def flag(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    class Order < ::Search::Order
      attribute :name, default: :asc
      attribute :registration_number
      attribute :status
      attribute :zip_code
      attribute :city_name
      attribute :area_type
    end

    class Chart < ::Search::Base::Chart
      group_by_attribute 'created_at', :date, sub_types: %i[by_month]
      group_by_attribute 'updated_at', :date, sub_types: %i[by_month]
      group_by_attribute 'zip_code', :string
      group_by_attribute 'city_name', :string
      group_by_attribute 'postal_region', :string
      group_by_attribute 'country_code', :string do
        def label(key)
          ISO3166::Country[key]&.translation(I18n.locale) || key
        end
      end
      group_by_attribute 'time_zone', :string

      group_by_attribute 'area_type', :string do
        def keys
          ::Chouette::AreaType::ALL.map(&:to_s)
        end

        def label(key)
          ::Chouette::AreaType.find(key).label
        end
      end

      group_by_attribute 'status', :string do
        def keys
          ::Chouette::StopArea.status.values
        end

        def label(key)
          I18n.t(key, scope: 'stop_areas.statuses')
        end
      end

      group_by_attribute 'is_referent', :string do
        def keys
          [true, false]
        end

        def label(key)
          I18n.t(key ? 'referent' : 'particular', scope: 'chart.values.stop_area.is_referent')
        end
      end

      group_by_attribute 'stop_area_provider_id', :string, joins: { stop_area_provider: {} }, selects: %w[stop_area_providers.name]

      group_by_attribute 'transport_mode', :string do
        def label(key)
          key.human_name
        end
      end
    end
  end
end
