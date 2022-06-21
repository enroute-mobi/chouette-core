class DocumentProvider < ActiveRecord::Base
	belongs_to :workbench, required: true

  has_many :documents
	
	validates :name, presence: true
end
