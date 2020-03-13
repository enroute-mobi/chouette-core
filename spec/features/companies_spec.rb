# -*- coding: utf-8 -*-

describe "Companies", :type => :feature do
  login_user

  let(:line_referential) { create :line_referential, member: @user.organisation }
  let!(:companies) { Array.new(2) { create :company, line_referential: line_referential } }
  subject { companies.first }

  describe "index" do
    before(:each) { visit line_referential_companies_path(line_referential) }

    it "displays companies" do
      expect(page).to have_content(companies.first.name)
      expect(page).to have_content(companies.last.name)
    end

    context 'filtering' do
      it 'supports filtering by name' do
        fill_in 'q[name_or_short_id_cont]', with: companies.first.name
        click_button 'search-btn'
        expect(page).to have_content(companies.first.name)
        expect(page).not_to have_content(companies.last.name)
      end

      it 'supports filtering by objectid' do
        fill_in 'q[name_or_short_id_cont]', with: companies.first.get_objectid.short_id
        click_button 'search-btn'
        expect(page).to have_content(companies.first.name)
        expect(page).not_to have_content(companies.last.name)
      end
    end
  end

  describe "show" do
    it "displays line" do
      visit line_referential_company_path(line_referential, companies.first)
      expect(page).to have_content(companies.first.name)
    end
  end
end
