class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable, :database_authenticatable

  @@authentication_type = "#{Rails.application.config.chouette_authentication_settings[:type]}_authenticatable".to_sym
  cattr_reader :authentication_type

  devise :invitable, :registerable, :validatable, :lockable,
         :recoverable, :rememberable, :trackable, :async, authentication_type

  # FIXME https://github.com/nbudin/devise_cas_authenticatable/issues/53
  # Work around :validatable, when database_authenticatable is diabled.
  attr_accessor :password unless authentication_type == :database_authenticatable

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :current_password, :password_confirmation, :remember_me, :name, :organisation_attributes
  belongs_to :organisation
  has_many :workbenches, through: :organisation
  accepts_nested_attributes_for :organisation

  validates :organisation, :presence => true
  validates :email, :presence => true, :uniqueness => true
  validates :name, :presence => true

  before_validation(:on => :create) do
    self.password ||= Devise.friendly_token.first(6)
    self.password_confirmation ||= self.password
  end
  after_destroy :check_destroy_organisation

  scope :with_organisation, -> { where.not(organisation_id: nil) }


  # Callback invoked by DeviseCasAuthenticable::Model#authernticate_with_cas_ticket
  def cas_extra_attributes=(extra_attributes)
    extra             = extra_attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    self.name         = extra[:full_name]
    self.email        = extra[:email]
    self.organisation = Organisation.sync_update extra[:organisation_code], extra[:organisation_name], extra[:functional_scope]
    self.permissions  = Stif::PermissionTranslator.translate(extra[:permissions], self.organisation)
  end

  def self.portail_api_request
    conf = Rails.application.config.try(:stif_portail_api)
    raise 'Rails.application.config.stif_portail_api configuration is not defined' unless conf

    HTTPService.get_json_resource(
      host: conf[:url],
      path: '/api/v1/users',
      token: conf[:key])
  end

  def self.portail_sync
    self.portail_api_request.each do |el|
      user              = User.find_or_initialize_by(username: el['username'])
      user.name         = "#{el['firstname']} #{el['lastname']}"
      user.email        = el['email']
      user.locked_at    = el['locked_at']
      user.organisation = Organisation.sync_update el['organization_code'], el['organization_name'], el['functional_scope']
      user.synced_at    = Time.now
      user.permissions  = Stif::PermissionTranslator.translate(el['permissions'])
      user.save
    end
  end

  def has_permission?(permission)
    permissions && permissions.include?(permission)
  end

  def can_monitor_sidekiq?
    has_permission?("sidekiq.monitor")
  end

  private

  # remove organisation and referentials if last user of it
  def check_destroy_organisation
    if organisation.users.empty?
      organisation.destroy
    end
  end

end
