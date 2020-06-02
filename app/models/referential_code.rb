class ReferentialCode < ActiveRecord::Base

  acts_as_copy_target

  belongs_to :code_space
  belongs_to :resource, polymorphic: true
  validates :value, presence: true

end
