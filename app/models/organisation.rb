# frozen_string_literal: true

class Organisation < ApplicationModel
  include DataFormatEnumerations

  has_one :authentication, class_name: 'Authentication::Base', dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :referentials, dependent: :destroy

  has_many :stop_area_referential_memberships, dependent: :destroy
  has_many :stop_area_referentials, through: :stop_area_referential_memberships

  has_many :line_referential_memberships, dependent: :destroy
  has_many :line_referentials, through: :line_referential_memberships

  has_many :workbenches, dependent: :destroy
  has_many :line_providers, through: :workbenches
  has_many :workgroups, -> { distinct }, through: :workbenches do
    def owned
      where(owner_id: proxy_association.owner.id).distinct
    end
  end
  has_many :custom_fields, through: :workgroups
  has_many :imports, through: :workbenches, class_name: "Import::Base"
  has_many :exports, through: :workbenches, class_name: "Export::Base"
  has_many :api_keys, through: :workbenches

  has_many :calendars, through: :workbenches

  validates_presence_of :name
  validates_uniqueness_of :code

  accepts_nested_attributes_for :authentication, allow_destroy: true, update_only: true

  def functional_scope
    JSON.parse( (sso_attributes || {}).fetch('functional_scope', '[]') )
  end

  def lines_set
    STIF::CodifligneLineId.lines_set_from_functional_scope( functional_scope )
  end

  def has_feature?(feature)
    features && features.include?(feature.to_s)
  end

  def owned_workgroups
    workgroups.owned
  end

  def lines_scope
    functional_scope = sso_attributes.try(:[], "functional_scope")
    JSON.parse(functional_scope) if functional_scope
  end

  def build_workbench_confirmation(attributes = {})
    Workbench::Confirmation.new(attributes.merge(organisation: self))
  end
end
