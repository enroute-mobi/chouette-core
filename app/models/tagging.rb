class Tagging < ApplicationModel
  belongs_to :tag
  belongs_to :taggable, polymorphic: true
end