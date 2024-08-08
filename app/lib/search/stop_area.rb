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
  end
end
