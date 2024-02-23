class AbstractCode < ActiveRecord::Base
  self.abstract_class = true

  acts_as_copy_target

  belongs_to :code_space, required: true
  belongs_to :resource, polymorphic: true, required: true

  validates :value, presence: true
end