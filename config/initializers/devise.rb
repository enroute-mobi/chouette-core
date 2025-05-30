# frozen_string_literal: true

# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
 # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  # config.secret_key =  Rails.env.production? ? ENV['DEVISE_SECRET_KEY'] : 'e9b20cea45078c982c9cd42cc64c484071d582a3d366ad2b51f676d168bccb2e0fd20e87ebe64aff57ad7f8a1a1c50b76cb9dc4039c287a195f9621fdb557993'

  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in Devise::Mailer,
  # note that it will be overwritten if you use your own mailer class
  # with default "from" parameter.
  config.mailer_sender = Rails.application.config.mailer_sender

  # Configure the class responsible to send e-mails.
  config.mailer = "DeviseMailer"

  config.email_regexp = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

   # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/active_record'

   # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  # config.authentication_keys = [ :email ]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # config.request_keys = []

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [ :email ]

 # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  config.strip_whitespace_keys = [ :email ]

  # Tell if authentication through request.params is enabled. True by default.
  # It can be set to an array that will enable params authentication only for the
  # given strategies, for example, `config.params_authenticatable = [:database]` will
  # enable it only for database (email + password) authentication.
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Auth is enabled. False by default.
  # It can be set to an array that will enable http authentication only for the
  # given strategies, for example, `config.http_authenticatable = [:database]` will
  # enable it only for database authentication. The supported strategies are:
  # :database      = Support basic authentication with authentication key + password
  # config.http_authenticatable = false

  # If 401 status code should be returned for AJAX requests. True by default.
  # config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication. 'Application' by default.
  # config.http_authentication_realm = 'Application'

  # It will change confirmation, password recovery and other workflows
  # to behave the same regardless if the e-mail provided was right or wrong.
  # Does not affect registerable.
  # config.paranoid = true

  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  # Notice that if you are skipping storage for all authentication paths, you
  # may want to disable generating routes to Devise's sessions controller by
  # passing skip: :sessions to `devise_for` in your config/routes.rb
  config.skip_session_storage = [:http_auth]

 # By default, Devise cleans up the CSRF token on authentication to
  # avoid CSRF token fixation attacks. This means that, when using AJAX
  # requests for sign in and sign up, you need to get a new CSRF token
  # from the server. You can disable this option at your own risk.
  # config.clean_up_csrf_token_on_authentication = true

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 10. If
  # using other encryptors, it sets how many times you want the password re-encrypted.
  #
  # Limiting the stretches to just one in testing will increase the performance of
  # your test suite dramatically. However, it is STRONGLY RECOMMENDED to not use
  # a value less than 10 in other environments. Note that, for bcrypt (the default
  # encryptor), the cost increases exponentially with the number of stretches (e.g.
  # a value of 20 is already extremely slow: approx. 60 seconds for 1 calculation).
  config.stretches = Rails.env.test? ? 1 : 10

  # Setup a pepper to generate the encrypted password.
  # config.pepper = "0420ef6a1b6b0ac63b9ac1e2b9624b411e331345a1bad99c85986f70aef62e9c7912955ea1616135224fc7c4ac319085a5e33831fb215a5e45043816746a2c2f"

  # ==> Configuration for :invitable
  # The period the generated invitation token is valid, after
  # this period, the invited resource won't be able to accept the invitation.
  # When invite_for is 0 (the default), the invitation won't expire.
  # config.invite_for = 2.weeks

  # Number of invitations users can send.
  # If invitation_limit is nil, users can send unlimited invitations.
  # If invitation_limit is 0, users can't send invitations.
  # If invitation_limit n > 0, users can send n invitations.
  # Default: nil
  # config.invitation_limit = 5

  # The key to be used to check existing users when sending an invitation
  # config.invite_key = :email

  # Flag that force a record to be valid before being actually invited
  # Default: false
  # config.validate_on_invite = true

# ==> Configuration for :confirmable
  # A period that the user is allowed to access the website even without
  # confirming their account. For instance, if set to 2.days, the user will be
  # able to access the website for two days without confirming their account,
  # access will be blocked just in the third day. Default is 0.days, meaning
  # the user cannot access the website without confirming their account.
  # config.allow_unconfirmed_access_for = 2.days

  # A period that the user is allowed to confirm their account before their
  # token becomes invalid. For example, if set to 3.days, the user can confirm
  # their account within 3 days after the mail was sent, but on the fourth day
  # their account can't be confirmed with the token any more.
  # Default is nil, meaning there is no restriction on how long a user can take
  # before confirming their account.
  # config.confirm_within = 3.days

  # If true, requires any email changes to be confirmed (exactly the same way as
  # initial account confirmation) to be applied. Requires additional unconfirmed_email
  # db field (see migrations). Until confirmed, new email is stored in
  # unconfirmed_email column, and copied to email column on successful confirmation.
  config.reconfirmable = false

  # Defines which key will be used when confirming an account
  # config.confirmation_keys = [ :email ]

  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  # config.remember_for = 2.weeks

  # Invalidates all the remember me tokens when the user signs out.
  config.expire_all_remember_me_on_sign_out = true

  # If true, extends the user's remember period when remembered via cookie.
  # config.extend_remember_period = false

  # Options to be passed to the created cookie. For instance, you can set
  # secure: true in order to force SSL only cookies.
  config.rememberable_options = { key: 'chouette-remember' }

  # ==> Configuration for :validatable
  # Range for password length.
  config.password_length = 9..128

  # Email regex used to validate email formats. It simply asserts that
  # one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  # config.email_regexp = /\A[^@]+@[^@]+\z/

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again. Default is 30 minutes.
  config.timeout_in = 1.hour

  # If true, expires auth token on session timeout.
  # config.expire_auth_token_on_timeout = false

  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  # config.lock_strategy = :failed_attempts

  # Defines which key will be used when locking and unlocking an account
  # config.unlock_keys = [ :email ]

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  # config.unlock_strategy = :both

  # Number of authentication tries before locking an account if lock_strategy
  # is failed attempts.
  # config.maximum_attempts = 20

  # Time interval to unlock the account if :time is enabled as unlock_strategy.
  # config.unlock_in = 1.hour

  # Warn on the last attempt before the account is locked.
  # config.last_attempt_warning = true

  # ==> Configuration for :recoverable
  #
  # Defines which key will be used when recovering the password for an account
  # config.reset_password_keys = [ :email ]

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  config.reset_password_within = 6.hours

  # ==> Configuration for :encryptable
  # Allow you to use another encryption algorithm besides bcrypt (default). You can use
  # :sha1, :sha512 or encryptors from others authentication tools as :clearance_sha1,
  # :authlogic_sha512 (then you should set stretches above to 20 for default behavior)
  # and :restful_authentication_sha1 (then you should set stretches to 10, and copy
  # REST_AUTH_SITE_KEY to pepper).
  #
  # Require the `devise-encryptable` gem when using anything other than bcrypt
  config.encryptor = :sha1

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # config.scoped_views = false

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes (usually :user).
  # config.default_scope = :user

  # Set this configuration to false if you want /users/sign_out to sign out
  # only the current scope. By default, Devise signs out all scopes.
  # config.sign_out_all_scopes = true

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html, should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  #
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists.
  #
  # The "*/*" below is required to match Internet Explorer requests.
  # config.navigational_formats = ['*/*', :html]

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = :delete

  # ==> OmniAuth
  # Add a new OmniAuth provider. Check the wiki for more information on setting
  # up on your models and hooks.
  # config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'

  # ==> Warden configuration
  # If you want to use other strategies, that are not supported by Devise, or
  # change the failure app, you can configure them inside the config.warden block.
  #
  # config.warden do |manager|
  #   manager.intercept_401 = false
  #   manager.default_strategies(scope: :user).unshift :some_external_strategy
  # end

  # ==> Mountable engine configurations
  # When using Devise inside an engine, let's call it `MyEngine`, and this engine
  # is mountable, there are some extra configurations to be taken into account.
  # The following options are available, assuming the engine is mounted as:
  #
  #     mount MyEngine, at: '/my_engine'
  #
  # The router that invoked `devise_for`, in the example above, would be:
  # config.router_name = :my_engine
  #
  # When using omniauth, Devise cannot automatically set Omniauth path,
  # so you need to do it manually. For the users scope, it would be:
  # config.omniauth_path_prefix = '/my_engine/users/auth'

  if Rails.application.config.chouette_authentication_settings[:type] == "cas"
    config.cas_base_url = Rails.application.config.chouette_authentication_settings[:cas_server]
    config.cas_validate_url = Rails.application.config.chouette_authentication_settings[:cas_validate_url]
  end

  # you can override these if you need to, but cas_base_url is usually enough
  # config.cas_login_url = "https://cas.myorganization.com/login"
  # config.cas_logout_url = "https://cas.myorganization.com/logout"
  # config.cas_validate_url = "https://cas.myorganization.com/serviceValidate"

  # The CAS specification allows for the passing of a follow URL to be displayed when
  # a user logs out on the CAS server. RubyCAS-Server also supports redirecting to a
  # URL via the destination param. Set either of these urls and specify either nil,
  # 'destination' or 'follow' as the logout_url_param. If the urls are blank but
  # logout_url_param is set, a default will be detected for the service.
  # config.cas_destination_url = 'https://cas.myorganization.com'
  # config.cas_follow_url = 'https://cas.myorganization.com'
  # config.cas_logout_url_param = nil

  # You can specify the name of the destination argument with the following option.
  # e.g. the following option will change it from 'destination' to 'url'
  # config.cas_destination_logout_param_name = 'url'

  # By default, devise_cas_authenticatable will create users.  If you would rather
  # require user records to already exist locally before they can authenticate via
  # CAS, uncomment the following line.
  # config.cas_create_user = false

  # You can enable Single Sign Out, which by default is disabled.
  # config.cas_enable_single_sign_out = true

  # If you don't want to use the username returned from your CAS server as the unique
  # identifier, but some other field passed in cas_extra_attributes, you can specify
  # the field name here.
  # config.cas_user_identifier = nil

  # If you want to use the Devise Timeoutable module with single sign out,
  # uncommenting this will redirect timeouts to the logout url, so that the CAS can
  # take care of signing out the other serviced applocations. Note that each
  # application manages timeouts independently, so one application timing out will
  # kill the session on all applications serviced by the CAS.
  # config.warden do |manager|
  #   manager.failure_app = DeviseCasAuthenticatable::SingleSignOut::WardenFailureApp
  # end

  # If you need to specify some extra configs for rubycas-client, you can do this via:
  # config.cas_client_config_options = {
  #     logger: Rails.logger
  # }

  # ==> Configuration for :saml_authenticatable
  # Create user if the user does not exist. (Default is false)
  # Can also accept a proc, for ex:
  # Devise.saml_create_user = Proc.new do |model_class, saml_response, auth_value|
  #  model_class == Admin
  # end
  # config.saml_create_user = false

  # Update the attributes of the user after a successful login. (Default is false)
  # Can also accept a proc, for ex:
  # Devise.saml_update_user = Proc.new do |model_class, saml_response, auth_value|
  #  model_class == Admin
  # end
  # config.saml_update_user = false

  # Lambda that is called if Devise.saml_update_user and/or Devise.saml_create_user are true.
  # Receives the model object, saml_response and auth_value, and defines how the object's values are
  # updated with regards to the SAML response.
  # config.saml_update_resource_hook = -> (user, saml_response, auth_value) {
  #   saml_response.attributes.resource_keys.each do |key|
  #     user.send "#{key}=", saml_response.attribute_value_by_resource_key(key)
  #   end
  #
  #   if (Devise.saml_use_subject)
  #     user.send "#{Devise.saml_default_user_key}=", auth_value
  #   end
  #
  #   user.save!
  # }

  # Lambda that is called to resolve the saml_response and auth_value into the correct user object.
  # Receives a copy of the ActiveRecord::Model, saml_response and auth_value. Is expected to return
  # one instance of the provided model that is the matched account, or nil if none exists.
  # config.saml_resource_locator = -> (model, saml_response, auth_value) {
  #   model.find_by(Devise.saml_default_user_key => auth_value)
  # }

  # Set the default user key. The user will be looked up by this key. Make
  # sure that the Authentication Response includes the attribute.
  config.saml_default_user_key = :email

  # Optional. This stores the session index defined by the IDP during login. If provided it will be used as a salt
  # for the user's session to facilitate an IDP initiated logout request.
  config.saml_session_index_key = nil

  # You can set this value to use Subject or SAML assertion as info to which email will be compared.
  # If you don't set it then email will be extracted from SAML assertion attributes.
  config.saml_use_subject = false

  # You can implement IdP settings with the options to support multiple IdPs and use the request object by setting this value to the name of a class that implements a ::settings method
  # which takes an IdP entity id and a request object as arguments and returns a hash of idp settings for the corresponding IdP.
  config.idp_settings_adapter = 'Chouette::Devise::Saml'

  # You provide you own method to find the idp_entity_id in a SAML message in the case of multiple IdPs
  # by setting this to the name of a custom reader class, or use the default.
  config.idp_entity_id_reader = 'Chouette::Devise::Saml'

  # You can set the name of a class that takes the response for a failed SAML request and the strategy,
  # and implements a #handle method. This method can then redirect the user, return error messages, etc.
  # config.saml_failed_callback = "MySamlFailedCallbacksHandler"

  # You can customize the named routes generated in case of named route collisions with
  # other Devise modules or libraries. Set the saml_route_helper_prefix to a string that will
  # be appended to the named route.
  # If saml_route_helper_prefix = 'saml' then the new_user_session route becomes new_saml_user_session
  config.saml_route_helper_prefix = 'saml'

  # You can add allowance for clock drift between the sp and idp.
  # This is a time in seconds.
  # config.allowed_clock_drift_in_seconds = 0

  # In SAML responses, validate that the identity provider has included an InResponseTo
  # header that matches the ID of the SAML request. (Default is false)
  # config.saml_validate_in_response_to = false

  config.saml_attribute_map_resolver = 'Chouette::Devise::Saml::AttributeMapResolver'

  config.saml_resource_validator_hook = lambda do |resource, decorated_response, _auth_value|
    return true unless resource

    resource.organisation&.authentication&.saml_idp_entity_id == decorated_response.raw_response.issuers.first
  end
end

Devise::Mailer.class_eval do
  helper :mailer
end

require Rails.root.join('lib/devise/hooks/invite_on_saml_session')
