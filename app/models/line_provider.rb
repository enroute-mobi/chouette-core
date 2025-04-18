# frozen_string_literal: true

class LineProvider < ApplicationModel
  include CodeSupport

  belongs_to :line_referential # CHOUETTE-3247 required: true
  belongs_to :workbench # CHOUETTE-3247 required: true
  has_many :lines, class_name: 'Chouette::Line'
  has_many :companies, class_name: 'Chouette::Company'
  has_many :networks, class_name: 'Chouette::Network'
  has_many :line_notices, class_name: 'Chouette::LineNotice'
  has_many :line_routing_constraint_zones
  has_many :line_groups, inverse_of: :line_provider
  has_many :booking_arrangements, class_name: 'BookingArrangement'

  validates :name, presence: true
  validates :short_name, presence: true, uniqueness: { scope: :workbench }, format: { with: /\A[0-9a-zA-Z_]+\Z/ }

  before_validation :define_line_referential, on: :create

  scope :by_text, lambda { |text|
                    text.blank? ? all : where('lower(line_providers.short_name) LIKE :t', t: "%#{text.downcase}%")
                  }

  def workgroup
    workbench&.workgroup
  end

  def used?
    [lines, companies, networks, line_notices, line_routing_constraint_zones].any?(&:exists?)
  end

  private

  def define_line_referential
    self.line_referential ||= workgroup&.line_referential
  end
end
