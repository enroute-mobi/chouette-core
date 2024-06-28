# frozen_string_literal: true

class User < ApplicationModel
  extend Enumerize
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable, :database_authenticatable

  @@authentication_type = "#{Rails.application.config.chouette_authentication_settings[:type]}_authenticatable".to_sym
  cattr_reader :authentication_type
  cattr_accessor :cas_updater

  def self.more_devise_modules
    if Subscription.enabled?
      [:confirmable]
    else
      []
    end
  end

  devise :invitable, :registerable, :validatable, :lockable, :timeoutable,
         :recoverable, :rememberable, :trackable, :saml_authenticatable, authentication_type, *more_devise_modules

  if Subscription.enabled?
    self.allow_unconfirmed_access_for = 1.day
  end

  # FIXME https://github.com/nbudin/devise_cas_authenticatable/issues/53
  # Work around :validatable, when database_authenticatable is disabled.
  attr_accessor :password unless authentication_type == :database_authenticatable

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :current_password, :password_confirmation, :remember_me, :name, :organisation_attributes
  belongs_to :organisation
  has_many :organisation_workbenches, class_name: 'Workbench', through: :organisation, source: :workbenches
  has_many :workbench_sharings, class_name: 'Workbench::Sharing', dependent: :destroy,
                                as: :recipient, inverse_of: :recipient
  has_many :shared_workbenches, class_name: 'Workbench', through: :workbench_sharings, source: :workbench
  has_many :workgroups, through: :organisation_workbenches
  has_many :imports, dependent: :nullify, class_name: 'Import::Base'
  has_many :exports, dependent: :nullify, class_name: 'Export::Base'
  has_many :merges, dependent: :nullify
  has_many :aggregates, dependent: :nullify
  accepts_nested_attributes_for :organisation

  validates :organisation, presence: true
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :enable_internal_password_authentication, inclusion: { in: [true, false] }

  enumerize :user_locale, in: %w(fr en), default: 'fr'

  after_initialize do
    self.profile ||= :custom
  end

  before_validation do
    # we sort permissions to make it easier to match them against profiles
    self.permissions&.sort!
    if permissions_changed?
      matching_profile = Permission::Profile.profile_for(permissions)
      write_attribute :profile, matching_profile
      self[:profile] = matching_profile
    end
  end

  scope :with_organisation, -> { where.not(organisation_id: nil) }

  scope :from_workgroup, ->(workgroup_id) { joins(:workbenches).where(workbenches: {workgroup_id: workgroup_id}) }

  scope :with_profiles, ->(*profile_names) { where(profile: profile_names) }

  scope :active, ->() { where(locked_at: nil) }

  scope :with_states, ->(*states) do
    subqueries = states.select(&:present?).map{|state| "(#{subquery_for_state(state)})" }
    where(subqueries.join(' OR '))
  end

  scope :by_text, -> (text) { text.blank? ? all : where('lower(users.email) LIKE :t or lower(users.name) LIKE :t', t: "%#{text}%") }

  def self.ransackable_scopes(auth_object = nil)
    super + %w[with_profiles with_states]
  end

  # called in Chouette::WorkgroupController:
  #   - begin_of_association_chain = user inherited from Chouette::UserController
  #   - belongs_to :workgroup, collection_name: :owned_workgroups defined in Chouette::WorkgroupController
  def owned_workgroups
    organisation&.owned_workgroups || Workgroup.none
  end

  def workbenches
    Workbench.left_outer_joins(:sharings) \
             .where(workbenches: { organisation_id: organisation_id }) \
             .or(
               Workbench.left_outer_joins(:sharings) \
                        .where(workbench_sharings: { recipient_type: 'User', recipient_id: id })
             ).or(
               Workbench.left_outer_joins(:sharings) \
                        .where(workbench_sharings: { recipient_type: 'Organisation', recipient_id: organisation_id })
             ) \
             .distinct
  end

  # Callback invoked by DeviseCasAuthenticable::Model#authernticate_with_cas_ticket
  def cas_extra_attributes=(extra_attributes)
     self.class.cas_updater&.update self, extra_attributes
  end

  def has_permission?(permission)
    permissions && permissions.include?(permission)
  end

  def can_monitor_sidekiq?
    has_permission?("sidekiq.monitor")
  end

  def email_recipient
    "#{name} <#{email}>"
  end

  def profile=(profile_name)
    write_attribute :profile, profile_name
    return if profile_name.to_s == Permission::Profile::DEFAULT_PROFILE.to_s

    new_permissions = Permission::Profile.permissions_for(profile_name)
    write_attribute :permissions, new_permissions
    self[:permissions] = new_permissions
  end

  def blocked?
    locked_at.present?
  end
  alias_method :locked?, :blocked?

  def invited?
    invitation_sent_at.present? && !invitation_accepted?
  end

  def invitation_accepted?
    invitation_accepted_at.present?
  end

  def confirmed?
    confirmed_at.present? && !invited? || invitation_accepted?
  end

  def belongs_to_workgroup_owner?(workgroup)
    return false unless workgroup

    workgroup.owner == organisation
  end

  def state
    %i[blocked confirmed invited].each do |s|
      return s if send("#{s}?")
    end

    :pending
  end

  def self.all_states
    %i[blocked confirmed invited pending]
  end

  def self.all_states_i18n
    all_states.map {|p| ["users.states.#{p}".t, p.to_s]}
  end

  def self.subquery_for_state(state)
    case state.to_s

    when 'blocked'
      'locked_at IS NOT NULL'
    when 'confirmed'
      'confirmed_at IS NOT NULL AND locked_at IS NULL AND (invitation_sent_at IS NULL OR invitation_accepted_at IS NOT NULL)'
    when 'invited'
      'invitation_sent_at IS NOT NULL AND invitation_accepted_at IS NULL AND locked_at IS NULL'
    when 'pending'
      'invitation_sent_at IS NULL AND confirmed_at IS NULL AND locked_at IS NULL'
    end
  end

  def self.invite(email:, name:, profile:, organisation:, from_user: )
    user = User.where(email: email).last
    if user
      return [true, nil] if user.organisation != organisation

      user.name = name
      user.profile = profile
      return [true, user]
    end

    user = User.new(
      email: email, name: name, profile: profile, organisation: organisation
    ).with_random_password

    user.try(:skip_confirmation!)
    user.save!
    user.invite_from_user! from_user
    [false, user]
  end

  def invite_from_user!(from_user)
    generate_invitation_token!
    update invitation_sent_at: Time.now
    UserMailer.invitation_from_user(self, from_user).deliver_now
  end

  def must_sign_in_with_saml?
    !enable_internal_password_authentication && organisation&.authentication&.is_a?(Authentication::Saml)
  end

  module Password
    extend ActiveSupport::Concern

    included do
      validate :validate_password_complexity
    end

    def with_random_password
      password = SecureRandom.alphanumeric(27) + \
                 PASSWORD_CHARS.sample + \
                 PASSWORD_NUMBERS.sample + \
                 PASSWORD_SPECIALS.sample
      password = password.chars.shuffle.join
      self.password = self.password_confirmation = password
      self
    end

    private

    def validate_password_complexity
      return if password.blank?
      return if password.match(PASSWORD_REGEXP)

      errors.add(:password, :must_be_complex)
    end

    PASSWORD_CHARS = (('A'..'Z').to_a + ('a'..'z').to_a).freeze
    PASSWORD_NUMBERS = ('0'..'9').to_a.freeze
    PASSWORD_SPECIALS = (('!'..'~').to_a - PASSWORD_CHARS - PASSWORD_NUMBERS).freeze
    PASSWORD_REGEXP = /(?=.*[a-zA-Z])(?=.*\d)(?=.*[^a-zA-Z\d])/.freeze
  end
  include Password
end
