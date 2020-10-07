
include Warden::Test::Helpers
Warden.test_mode!

# Feature: User profile page
#   As a user
#   I want to visit my user profile page
#   So I can see my personal account data
feature 'User profile page', :devise do

  after(:each) do
    Warden.test_reset!
  end

  # Scenario: User sees own profile
  #   Given I am signed in
  #   When I visit the user profile page
  #   Then I see my own email address
  scenario 'user sees own profile' do
    user = FactoryBot.create(:user)
    user.organisation.workbenches << create(:workbench)
    login_as(user, :scope => :user)
    visit organisation_user_path(user)
    # FIXME ref #819
    # expect(page).to have_content 'Mon Profil'
    expect(page).to have_content user.email
  end

  # Scenario: User cannot see another user's profile
  #   Given I am signed in
  #   When I visit another user's profile
  #   Then I see an 'access denied' message
  scenario "user cannot see another user's profile" do
    me = FactoryBot.create(:user)
    me.organisation.workbenches << create(:workbench)
    other = FactoryBot.create(:user, email: 'other@example.com', :organisation => me.organisation)
    login_as(me, :scope => :user)
    Capybara.current_session.driver.header 'Referer', authenticated_root_path
    visit organisation_user_path(other)
    expect(page).to have_content other.email
  end

end
