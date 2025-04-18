# frozen_string_literal: true

module Chouette
  class LineNotice < Chouette::ActiveRecord
    has_metadata
    include LineReferentialSupport
    include ObjectidSupport
    include CodeSupport

    # We will protect the notices that are used by vehicle_journeys
    scope :unprotected, lambda {
      subquery = CrossReferentialIndexEntry.where(relation_name: :line_notices).select(:parent_id).distinct
      where.not("id in (#{subquery.to_sql})")
    }

    scope :autocomplete, lambda { |q|
      if q.present?
        where("title ILIKE '%#{sanitize_sql_like(q)}%'")
      else
        all
      end
    }
    scope :by_text, ->(text) { text.blank? ? all : where('lower(line_notices.title) LIKE :t', t: "%#{text.downcase}%") }

    scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }

    scope :with_lines, ->(lines) { joins(:line_notice_memberships).where(line_notices_lines: { line_id: lines }) }

    has_many :line_notice_memberships, inverse_of: :line_notice, dependent: :destroy
    has_many :lines, through: :line_notice_memberships, inverse_of: :line_notices
    has_many_scattered :vehicle_journeys

    validates :title, presence: true

    alias_attribute :name, :title

    def self.nullable_attributes
      %i[content import_xml]
    end

    def protected?
      vehicle_journeys.exists?
    end
    alias used? protected?
  end
end
