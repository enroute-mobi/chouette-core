class DocumentMembership < ApplicationModel
  belongs_to :document
  belongs_to :documentable, polymorphic: true

  validates :document, :documentable, presence: true
end
