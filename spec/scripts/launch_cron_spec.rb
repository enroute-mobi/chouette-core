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
    DD_AGENT_APP DD_TRACE_DEBUG DD_AGENT_ENV DD_AGENT_HOST SESAME_API_SETTINGS
    RAILS_DB_HOST RAILS_DB_PORT RAILS_DB_USER RAILS_DB_PASSWORD RAILS_DB_NAME
    PUBLIC_HOST MAIL_FROM SMTP_HOST SECRET_BASE CODIFLIGNE_API_URL REFLEX_API_URL
    REDIS_CACHE_STORE_URL RAILS_LOG_TO_STDOUT NR_LICENCE_KEY CHOUETTE_CLEAN_TEST_ORGANISATIONS
    AUTOMATED_AUDITS_ENABLED CHOUETTE_EMAIL_USER CHOUETTE_EMAIL_WHITELIST CHOUETTE_EMAIL_BLACKLIST
    REFERENTIALS_CLEANING_COOLDOWN TZ SMTP_SETTINGS PUBLIC_HOST MAIL_DELIVERY_METHOD MAIL_FROM
    GEM_HOME BUNDLE_APP_CONFIG BUNDLE_PATH BUNDLE_SILENCE_ROOT_WARNING RUBYOPT
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
