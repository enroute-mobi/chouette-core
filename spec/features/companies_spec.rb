describe "Companies", :type => :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        3.times { company }
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:companies) { context.line_referential.companies }
  subject { companies.first }

  describe "index" do
    before(:each) { visit workbench_line_referential_companies_path(workbench) }

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
      visit workbench_line_referential_company_path(workbench, companies.first)
      expect(page).to have_content(companies.first.name)
    end
  end
end
