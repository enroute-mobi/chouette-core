module DeviseRequestHelper
  include Warden::Test::Helpers


  def login_user(stubbed: false)
    organisation = 
      if stubbed
        build_stubbed :organisation
      else
        Organisation.where(:code => "first").first_or_create(attributes_for(:organisation))
      end
    @user ||=
      if stubbed
        build_stubbed :allmighty_user, organisation: organisation
      else
       create :allmighty_user, :organisation => organisation
      end

    login_as @user, :scope => :user
    # post_via_redirect user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods

    def login_user(stubbed: false)
      before(:each) do
        login_user(stubbed: stubbed)
      end
      after(:each) do
        Warden.test_reset!
      end
    end

  end

end

module DeviseControllerHelper

  def setup_user
    _all_actions = %w{create destroy update}
    _all_resources = %w{ access_links
            access_points
            connection_links
            footnotes
            journey_patterns
            referentials
            route_sections
            routes
            routing_constraint_zones
            time_tables
            vehicle_journeys }
    join_with =  -> (separator) do 
      -> (ary) { ary.join(separator) }
    end

    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      organisation = Organisation.where(:code => "first").first_or_create(attributes_for(:organisation))
      @user = create(:user,
                     organisation: organisation,
                     permissions: _all_resources.product( _all_actions ).map(&join_with.('.')))
    end
  end

  def login_user()
    setup_user
    before do
      sign_in @user
    end
  end

  private

end

RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
  config.extend DeviseControllerHelper, :type => :controller

  config.include DeviseRequestHelper, :type => :request
  config.include DeviseRequestHelper, :type => :feature
end
