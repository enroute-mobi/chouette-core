class CodeSpace < ActiveRecord::Base

  belongs_to :workgroup
  validates :short_name, presence: true

  DEFAULT_SHORT_NAME = 'external'

end
