# coding: utf-8
class Organisation < ApplicationModel
  include DataFormatEnumerations

  has_many :users, :dependent => :destroy
  has_many :referentials, :dependent => :destroy
  has_many :compliance_control_sets, :dependent => :destroy

  has_many :stop_area_referential_memberships
  has_many :stop_area_referentials, through: :stop_area_referential_memberships

  has_many :line_referential_memberships
  has_many :line_referentials, through: :line_referential_memberships

  has_many :workbenches
  has_many :workgroups, through: :workbenches

  has_many :calendars
  has_many :api_keys, class_name: 'Api::V1::ApiKey'

  validates_presence_of :name
  validates_uniqueness_of :code

  class << self

    def portail_api_request
      conf = Rails.application.config.try(:stif_portail_api)
      raise 'Rails.application.config.stif_portail_api configuration is not defined' unless conf

      HTTPService.get_json_resource(
        host: conf[:url],
        path: '/api/v1/organizations',
        token: conf[:key])
    end

    def sync_update code, name, scopes
      org = Organisation.find_or_initialize_by(code: code)
      scopes.symbolize_keys!
      functional_scope = scopes[:functional_scope]
      if functional_scope
        org.sso_attributes ||= {}
        if org.sso_attributes['functional_scope'] != functional_scope
          org.sso_attributes['functional_scope'] = functional_scope
          # FIXME see #1941
          org.sso_attributes_will_change!
        end
      end
      stop_area_providers = scopes[:organisation_reflex_codes]
      if stop_area_providers
        org.sso_attributes ||= {}
        if org.sso_attributes['stop_area_providers'] != stop_area_providers
          org.sso_attributes['stop_area_providers'] = stop_area_providers
          # FIXME see #1941
          org.sso_attributes_will_change!
        end
      end
      org.name      = name
      org.synced_at = Time.now
      org.save
      org
    end

    def portail_sync
      portail_api_request.each do |el|
        org = self.sync_update el['code'], el['name'], el
        puts "✓ Organisation #{org.name} has been updated" unless Rails.env.test?
      end
    end
  end

  def find_referential(referential_id)
    organisation_referential = referentials.find_by id: referential_id
    return organisation_referential if organisation_referential

    # TODO: Replace each with find
    workbenches.each do |workbench|
      workbench_referential = workbench.all_referentials.find_by id: referential_id
      return workbench_referential if workbench_referential
    end

    raise ActiveRecord::RecordNotFound
  end

  def functional_scope
    JSON.parse( (sso_attributes || {}).fetch('functional_scope', '[]') )
  end

  def lines_set
    STIF::CodifligneLineId.lines_set_from_functional_scope( functional_scope )
  end

  def has_feature?(feature)
    features && features.include?(feature.to_s)
  end

  def default_workbench
    workbenches.default
  end

  def lines_scope
    functional_scope = sso_attributes.try(:[], "functional_scope")
    JSON.parse(functional_scope) if functional_scope
  end
end
