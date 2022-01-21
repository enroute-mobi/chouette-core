RSpec.describe "launch-cron" do

  describe "variables" do
    let(:env) { Hash.new }

    let(:ignored_variables) { %w{RAILS_DB_USER RAILS_DB_NAME GEM_HOME RUBYOPT} }

    def script_output
      # We're ignoring current RUBYOPT to avoid complex syntax in some environments like:
      # RUBYOPT=-r/var/lib/gems/2.7.0/gems/bundler-2.2.28/lib/bundler/setup
      # -W0
      env["RUBYOPT"] ||= ""

      env_definition = env.map { |k,v| "#{k}=\"#{v}\"" }.join(" ")
      %x{#{env_definition} ./script/launch-cron variables}
    end

    subject(:variables) do
      script_output.split.map do |line|
        if /^(?<key>[^=]+)=(?<value>.*)$/ =~ line
          [ key, value ]
        end
      end.to_h
    end

    SUPPORTED_VARIABLES = %w{
      AUTOMATED_AUDITS_ENABLED
      BUNDLE_APP_CONFIG
      BUNDLE_PATH
      BUNDLE_SILENCE_ROOT_WARNING
      CHOUETTE_CLEAN_TEST_ORGANISATIONS
      CHOUETTE_CLEAN_TEST_ORGANISATIONS_KEEP_COUNT
      CHOUETTE_EMAIL_BLACKLIST
      CHOUETTE_EMAIL_USER
      CHOUETTE_EMAIL_WHITELIST
      CODIFLIGNE_API_URL
      DD_AGENT_APP
      DD_AGENT_ENV
      DD_AGENT_HOST
      DD_TRACE_DEBUG
      GCLOUD_BUCKET
      GCLOUD_PROJECT
      GEM_HOME
      MAIL_DELIVERY_METHOD
      MAIL_FROM
      MAIL_FROM
      NR_LICENCE_KEY
      PUBLIC_HOST
      PUBLIC_HOST
      RAILS_DB_HOST
      RAILS_DB_NAME
      RAILS_DB_PASSWORD
      RAILS_DB_PORT
      RAILS_DB_USER
      RAILS_LOG_TO_STDOUT
      REDIS_CACHE_STORE_URL
      REFERENTIALS_CLEANING_COOLDOWN
      REFLEX_API_URL
      RUBYOPT
      SECRET_BASE
      SENTRY_APP
      SENTRY_CONTEXT
      SENTRY_CURRENT_ENV
      SENTRY_DSN
      SESAME_API_SETTINGS
      SMTP_HOST
      SMTP_SETTINGS
      STORAGE
      TZ
    }

    SUPPORTED_VARIABLES.sort.each do |variable|
      context "when #{variable} is defined" do
        before { env[variable] = "dummy" }
        it "should be present in cron variables" do
          is_expected.to include(variable => "dummy")
        end
      end
    end

    context "when PATH is defined" do
      it "should be present in cron variables" do
        is_expected.to include("PATH" => ENV["PATH"])
      end
    end

    context "when a variable has no value" do
      let(:variable) { SUPPORTED_VARIABLES.first }
      before { env[variable] = "" }

      it "should not be present in cron variables" do
        is_expected.to_not have_key(variable)
      end
    end

    context "when an unsupported variable is defined" do
      before { env["DUMMY"] = "defined" }

      it "should not be present in cron variables" do
        is_expected.to_not have_key("DUMMY")
      end
    end

  end
end
