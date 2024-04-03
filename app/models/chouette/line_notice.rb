# frozen_string_literal: true

module Chouette
  class LineNotice < Chouette::ActiveRecord
    has_metadata
    include LineReferentialSupport
    include ObjectidSupport

    # We will protect the notices that are used by vehicle_journeys
    scope :unprotected, -> {
      subquery = CrossReferentialIndexEntry.where(relation_name: :line_notices).select(:parent_id).distinct
      where.not("id in (#{subquery.to_sql})" )
    }

    scope :autocomplete, ->(q) {
      if q.present?
        where("title ILIKE '%#{sanitize_sql_like(q)}%'")
      else
        all
      end
    }
    scope :by_text, ->(text) { text.blank? ? all : where('lower(line_notices.title) LIKE :t', t: "%#{text.downcase}%") } 

    scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }

    belongs_to :line_referential, inverse_of: :line_notices
    has_and_belongs_to_many :lines, :class_name => 'Chouette::Line', :join_table => "public.line_notices_lines"
    has_many_scattered :vehicle_journeys

    validates_presence_of :title

    alias_attribute :name, :title

    def self.nullable_attributes
      [:content, :import_xml]
    end

    def protected?
      vehicle_journeys.exists?
    end
    alias used? protected?
  end
end
