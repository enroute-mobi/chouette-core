# -*- coding: utf-8 -*-

# Feature: Sign out
#   As a user
#   I want to sign out
#   So I can protect my account from unauthorized access
feature 'Sign out', :devise do

  # Scenario: User signs out successfully
  #   Given I am signed in
  #   When I sign out
  #   Then I see a signed out message

  # FIXME #816
  # scenario 'user signs out successfully' do
  #   user = FactoryGirl.create(:user)
  #   user.confirm!
  #   login_as(user, :scope => "user")
  #   expect(page).to have_content I18n.t 'devise.sessions.signed_in'
  #   click_link user.name
  #   click_link 'Déconnexion'
  #   expect(page).to have_content I18n.t 'devise.sessions.signed_out'
  # end

end


