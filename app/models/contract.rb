# frozen_string_literal: true

class Contract < ApplicationModel
  include CodeSupport

  belongs_to :company, required: true, class_name: 'Chouette::Company'
  belongs_to :workbench, required: true, class_name: 'Workbench'

  has_many :lines, class_name: 'Chouette::Line'
end