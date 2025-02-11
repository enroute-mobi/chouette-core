# frozen_string_literal: true

class LineReferential < ApplicationModel
  include ObjectidFormatterSupport

  has_many :line_referential_memberships, dependent: :destroy
  has_many :organisations, through: :line_referential_memberships
  has_many :lines, class_name: 'Chouette::Line', dependent: :destroy
  has_many :companies, class_name: 'Chouette::Company', dependent: :destroy
  has_many :networks, class_name: 'Chouette::Network', dependent: :destroy
  has_many :workbenches, dependent: :nullify
  has_many :line_notices, class_name: 'Chouette::LineNotice', inverse_of: :line_referential, dependent: :destroy
  has_many :line_routing_constraint_zones, dependent: :destroy
  has_many :booking_arrangements, dependent: :destroy
  has_many :line_groups, dependent: :destroy, inverse_of: :line_referential
  has_one  :workgroup, dependent: :nullify

  has_many :line_providers

  def add_member(organisation, options = {})
    attributes = options.merge organisation: organisation
    line_referential_memberships.build attributes unless organisations.include?(organisation)
  end

  validates :name, presence: true

  def operating_lines
    lines.where(deactivated: false)
  end
end
