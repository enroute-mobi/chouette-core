describe "Networks", type: :feature do
  login_user

  let(:line_referential) { create :line_referential }
  let!(:networks) { Array.new(2) { create(:network, line_referential: line_referential) } }
  subject { networks.first }
  before { @user.organisation.line_referentials << line_referential }

  describe "index" do
    before(:each) { visit line_referential_networks_path(line_referential) }

    it "displays networks" do
      expect(page).to have_content(networks.first.name)
      expect(page).to have_content(networks.last.name)
    end

    context 'filtering' do
      it 'supports filtering by name' do
        fill_in 'q[name_or_objectid_cont]', with: networks.first.name
        click_button 'search-btn'
        expect(page).to have_content(networks.first.name)
        expect(page).not_to have_content(networks.last.name)
      end

      it 'supports filtering by objectid' do
        fill_in 'q[name_or_objectid_cont]', with: networks.first.objectid
        click_button 'search-btn'
        expect(page).to have_content(networks.first.name)
        expect(page).not_to have_content(networks.last.name)
      end
    end
  end

  describe "show" do
    it "displays network" do
      visit line_referential_network_path(line_referential, networks.first)
      expect(page).to have_content(networks.first.name)
    end

    # it "display map" do
    #   # allow(subject).to receive(:stop_areas).and_return(Array.new(2) { create(:stop_area) })
    #   visit line_referential_networks_path(line_referential)
    #   click_link "#{networks.first.name}"
    #   expect(page).to have_selector("#map.network")
    # end

  end

  # Fixme #1780
  # describe "new" do
  #   it "creates network and return to show" do
  #     # allow(subject).to receive(:stop_areas).and_return(Array.new(2) { create(:stop_area) })
  #     visit line_referential_networks_path(line_referential)
  #     click_link "Ajouter un réseau"
  #     fill_in "network_name", :with => "Network 1"
  #     fill_in "Numéro d'enregistrement", :with => "test-1"
  #     fill_in "Identifiant Neptune", :with => "chouette:test:GroupOfLine:1"
  #     click_button("Créer réseau")
  #     expect(page).to have_content("Network 1")
  #   end
  # end

  # describe "edit and return to show" do
  #   it "edit network" do
  #     # allow(subject).to receive(:stop_areas).and_return(Array.new(2) { create(:stop_area) })
  #     visit line_referential_network_path(line_referential, subject)
  #     click_link "Editer ce réseau"
  #     fill_in "network_name", :with => "Network Modified"
  #     fill_in "Numéro d'enregistrement", :with => "test-1"
  #     click_button("Editer réseau")
  #     expect(page).to have_content("Network Modified")
  #   end
  # end

  # describe "delete", :js => true do
  #   it "delete network and return to the list" do
  #     subject.stub(:stop_areas).and_return(Array.new(2) { create(:stop_area) })
  #     visit line_referential_network_path(line_referential, subject)
  #     click_link "Supprimer ce réseau"
  #     page.evaluate_script('window.confirm = function() { return true; }')
  #     click_button "Valider"
  #     expect(page).to have_no_content(subject.name)
  #   end

  # end
end
