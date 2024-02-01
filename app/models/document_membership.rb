# frozen_string_literal: true

class DocumentMembership < ApplicationModel
  belongs_to :document
  belongs_to :documentable, polymorphic: true

  validates :document, :documentable, presence: true

  validates :document_id, uniqueness: { scope: %i[documentable_type documentable_id] }
end
