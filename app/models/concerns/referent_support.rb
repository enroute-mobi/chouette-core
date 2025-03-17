module ReferentSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :referent, class_name: name, optional: true # CHOUETTE-3247 code analysis
    validate :valid_referent

    scope :referents, -> { where is_referent: true }
    scope :particulars, -> { where.not is_referent: true }
    scope :with_referent, -> { where.not referent: nil }
    scope :without_referent, -> { where referent: nil }
    scope :referents_or_self, -> { unscoped.where(id: select("DISTINCT COALESCE(#{table_name}.referent_id, #{table_name}.id)")) }

    has_many :particulars, class_name: name, foreign_key: 'referent_id'

    def valid_referent
      if referent_id.present? && referent?
        errors.add :referent_id, :a_referent_cannot_have_a_referent
      end

      if referent.present? && !referent.referent?
        errors.add :referent_id, :an_object_used_as_referent_must_be_flagged_as_referent
      end

      if particular? && particulars.present?
        errors.add :is_referent, :the_particulars_collection_should_be_empty
      end
    end

    def referent?
      is_referent
    end

    def particular?
      !referent?
    end
  end

  module ClassMethods
    # DEPRECATED. Use referents scope
    def referent_only
      referents
    end

    def all_referents
      unscoped.where(id: with_referent.select(:referent_id).distinct)
    end

    def self_and_referents
      _union self, all_referents
    end

    private

    def _union(relation1, relation2)
      union_query = "select id from ((#{relation1.select(:id).to_sql}) UNION (#{relation2.select(:id).to_sql})) identifiers"
      unscoped.where "#{table_name}.id IN (#{union_query})"
    end
  end
end
