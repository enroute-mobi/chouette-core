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

  accepts_nested_attributes_for :organisation

  validates :organisation, :presence => true
  validates :email, :presence => true, :uniqueness => true
  validates :name, :presence => true

  before_validation(:on => :create) do
    self.password ||= Devise.friendly_token.first(6)
    self.password_confirmation ||= self.password
  end
  after_destroy :check_destroy_organisation

  def cas_extra_attributes=(extra_attributes)
    extra         = extra_attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    self.name     = extra[:full_name]
    self.email    = extra[:email]
    self.username = extra[:username]

    self.organisation = Organisation.find_or_create_by(code: extra[:organisation_code]).tap do |org|
      org.name      = extra[:organisation_name]
      org.synced_at = Time.now
    end
  end

  def self.portail_api_request
    conf = Rails.application.config.try(:stif_portail_api)
    raise 'Rails.application.config.stif_portail_api settings is not defined' unless conf

    conn = Faraday.new(:url => conf[:url]) do |c|
      c.headers['Authorization'] = "Token token=\"#{conf[:key]}\""
      c.adapter  Faraday.default_adapter
    end

    resp = conn.get '/api/v1/users'
    if resp.status == 200
      JSON.parse resp.body
    else
      raise "Error on api request status : #{resp.status} => #{resp.body}"
    end
  end

  def self.portail_sync
    self.portail_api_request.each do |el|
      User.find_or_create_by(username: el['username']).tap do |user|
        user.name         = "#{el['firstname']} #{el['lastname']}"
        user.email        = el['email']
        user.locked_at    = el['locked_at']

        # Set organisation
        user.organisation = Organisation.find_or_create_by(code: el['organization_code']).tap do |org|
          org.name      = el['organization_name']
          org.synced_at = Time.now
        end

        if user.changed?
          user.synced_at = Time.now
          user.save
          puts "✓ user #{user.username} has been updated" unless Rails.env.test?
        end
      end
    end
  end

  private

  # remove organisation and referentials if last user of it
  def check_destroy_organisation
    if organisation.users.empty?
      organisation.destroy
    end
  end
end
