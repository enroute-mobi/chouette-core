module ReferentSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :referent, class_name: class_name
    validate :valid_referent

    has_many :particulars, class_name: class_name, foreign_key: 'referent_id'

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
    def class_name
      self.name
    end
  end
end
