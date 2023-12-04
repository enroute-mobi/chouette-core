# frozen_string_literal: true

class Contract < ApplicationModel
  include CodeSupport

  belongs_to :company, class_name: 'Chouette::Company' # CHOUETTE-3247 optional: false
  belongs_to :workbench, class_name: 'Workbench' # CHOUETTE-3247 optional: false

  has_array_of :lines, class_name: 'Chouette::Line'

  validates :name, :lines, presence: true

  def self.with_lines(*lines)
    lines = lines.flatten
    where('line_ids::integer[] && ARRAY[?]', lines.map(&:id))
  end
end
