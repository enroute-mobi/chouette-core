class RawImport < ApplicationModel
  belongs_to :model, polymorphic: true

end
