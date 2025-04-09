# Be sure to restart your server when you modify this file.

if Rails.application.config.chouette_authentication_settings[:type] == 'cas'
  Rails.application.config.session_store :cas_redis_store,
                                         servers: [SmartEnv['REDIS_URL']],
                                         key: '_chouette_session',
                                         expire_after: 1.day

  Rails.application.config.rack_cas.session_store = ActionDispatch::Session::CasRedisStore
else
  Rails.application.config.session_store :cookie_store, key: 'chouette-session'
end
