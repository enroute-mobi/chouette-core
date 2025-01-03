class RawImport < ApplicationModel
  belongs_to :model, polymorphic: true # TODO: CHOUETTE-3247 optional: true?
end
