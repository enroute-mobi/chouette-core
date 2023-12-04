# frozen_string_literal: true

class DocumentMembership < ApplicationModel
  belongs_to :document # CHOUETTE-3247 validates presence
  belongs_to :documentable, polymorphic: true # CHOUETTE-3247 validates presence

  validates :document_id, uniqueness: { scope: %i[documentable_type documentable_id] }
end
