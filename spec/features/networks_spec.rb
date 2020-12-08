describe "Networks", type: :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        3.times { network }
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:networks) { context.line_referential.networks }
  let(:other_network) { networks.last }
  subject { networks.first }

  describe "index" do
    before(:each) { visit workbench_line_referential_networks_path(workbench) }

    it "displays networks" do
      expect(page).to have_content(subject.name)
      expect(page).to have_content(other_network.name)
    end

    context 'filtering' do
      it 'supports filtering by name' do
        fill_in 'q[name_or_short_id_cont]', with: subject.name
        click_button 'search-btn'
        expect(page).to have_content(subject.name)
        expect(page).not_to have_content(other_network.name)
      end

      it 'supports filtering by objectid' do
        fill_in 'q[name_or_short_id_cont]', with: subject.get_objectid.short_id
        click_button 'search-btn'
        expect(page).to have_content(subject.name)
        expect(page).not_to have_content(other_network.name)
      end
    end
  end

  describe "show" do
    it "displays network" do
      visit workbench_line_referential_network_path(workbench, subject)
      expect(page).to have_content(subject.name)
    end
  end

end
