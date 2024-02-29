# frozen_string_literal: true

class Contract < ApplicationModel
  include CodeSupport

  belongs_to :company, optional: false, class_name: 'Chouette::Company'
  belongs_to :workbench, optional: false, class_name: 'Workbench'

  has_array_of :lines, class_name: 'Chouette::Line'

  validates :name, :lines, presence: true

  def self.with_lines(*lines)
    lines = lines.flatten
    where('line_ids::integer[] && ARRAY[?]', lines.map(&:id))
  end
end
