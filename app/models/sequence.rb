# frozen_string_literal: true

class Sequence < ApplicationModel
  extend Enumerize

  belongs_to :workbench, optional: false, class_name: 'Workbench'

  validates :name, :sequence_type, presence: true

  enumerize :sequence_type, in: %i[range_sequence], scope: true

end
