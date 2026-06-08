# frozen_string_literal: true

module Query
  class Publication < Query::Operation
    def text(value)
      change_scope(if: value.present?) do |scope|
        publications = scope.arel_table
        setup_ids = PublicationSetup.where(
          PublicationSetup.arel_table[:name].matches("%#{value}%")
        ).select(:id).arel

        scope.where(
          publications[:creator].matches("%#{value}%")
            .or(publications[:publication_setup_id].in(setup_ids))
        )
      end
    end

    def publication_setup_id(value)
      change_scope(if: value_present?(value)) do |scope|
        scope.where(publication_setup_id: value)
      end
    end

    def creator(value)
      where(value, :matches, :creator)
    end

    def export_type(value)
      change_scope(if: value_present?(value)) do |scope|
        scope.joins(:export).where(export: { type: value })
      end
    end
  end
end
