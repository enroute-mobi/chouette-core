class LineProvider < ApplicationModel

  belongs_to :line_referential, required: true
  belongs_to :workbench, required: true
  has_many :lines, class_name: "Chouette::Line"
 	has_many :companies, class_name: "Chouette::Company"
 	has_many :networks, class_name: "Chouette::Network"
 	has_many :group_of_lines, class_name: "Chouette::GroupOfLine"

  validates :short_name, presence: true

  before_validation :define_line_referential, on: :create

  private

  def define_line_referential
    self.line_referential ||= workbench&.workgroup&.line_referential
  end
end
