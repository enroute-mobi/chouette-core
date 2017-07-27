class Organisation < ActiveRecord::Base
  include DataFormatEnumerations

  has_many :users, :dependent => :destroy
  has_many :referentials, :dependent => :destroy
  has_many :rule_parameter_sets, :dependent => :destroy

  has_many :stop_area_referential_memberships
  has_many :stop_area_referentials, through: :stop_area_referential_memberships

  has_many :line_referential_memberships
  has_many :line_referentials, through: :line_referential_memberships

  has_many :workbenches
  has_many :calendars

  validates_presence_of :name
  validates_uniqueness_of :code

  after_create :add_rule_parameter_set

  def add_rule_parameter_set
    RuleParameterSet.default_for_all_modes( self).save
  end

  def self.portail_api_request
    conf = Rails.application.config.try(:stif_portail_api)
    raise 'Rails.application.config.stif_portail_api configuration is not defined' unless conf

    HTTPService.get_resource(
      host: conf[:url],
      path: '/api/v1/organizations',
      parse_json: true,
      token: conf[:key])
  end

  def self.sync_update code, name, scope
    org = Organisation.find_or_initialize_by(code: code)
    if scope
      org.sso_attributes ||= {}
      if org.sso_attributes['functional_scope'] != scope
        org.sso_attributes['functional_scope'] = scope
        # FIXME see #1941
        org.sso_attributes_will_change!
      end
    end
    org.name      = name
    org.synced_at = Time.now
    org.save
    org
  end

  def self.portail_sync
    self.portail_api_request.each do |el|
      org = self.sync_update el['code'], el['name'], el['functional_scope']
      puts "✓ Organisation #{org.name} has been updated" unless Rails.env.test?
    end
  end

  def find_referential(referential_id)
    organisation_referential = referentials.find_by id: referential_id
    return organisation_referential if organisation_referential

    workbenches.each do |workbench|
      workbench_referential = workbench.all_referentials.find_by id: referential_id
      return workbench_referential if workbench_referential
    end

    raise ActiveRecord::RecordNotFound
  end

end
