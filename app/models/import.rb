class Import < ActiveRecord::Base
  mount_uploader :file, ImportUploader
  belongs_to :workbench
  belongs_to :referential

  belongs_to :parent, class_name: to_s

  extend Enumerize
  enumerize :status, in: %i(new downloading analyzing pending successful failed running aborted canceled)

  validates :file, presence: true
  validates_presence_of :referential, :workbench

  before_create do
    self.token_download = SecureRandom.urlsafe_base64
    self.status = Import.status.new
  end
end
