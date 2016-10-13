class LineReferentialSyncMessage < ActiveRecord::Base
  belongs_to :line_referential_sync
  enum criticity: [:info, :warn, :error]

  validates :criticity, presence: true
end
