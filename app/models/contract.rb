# frozen_string_literal: true

class Contract < ApplicationModel
  include CodeSupport

  belongs_to :company, required: true, class_name: 'Chouette::Company'

  has_many :lines, class_name: 'Chouette::Line'
end