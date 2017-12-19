describe "Lines", type: :feature do
  login_user

  let(:line_referential) { create :line_referential }
  let!(:network) { create(:network) }
  let!(:company) { create(:company) }
  let!(:lines) { Array.new(2) { create :line_with_stop_areas, network: network, company: company, line_referential: line_referential } }
  let!(:group_of_line) { create(:group_of_line) }
  subject { lines.first }
  before { @user.organisation.line_referentials << line_referential }

  with_permissions "boiv:read" do
    describe "index" do
      before(:each) { visit line_referential_lines_path(line_referential) }

      it "displays lines" do
        expect(page).to have_content(lines.first.name)
        expect(page).to have_content(lines.last.name)
      end

      it 'allows only R in CRUD' do
        expect(page).to have_link(I18n.t('actions.show'))
        expect(page).not_to have_link(I18n.t('actions.edit'), href: edit_referential_line_path(referential, lines.first))
        expect(page).not_to have_link(I18n.t('actions.destroy'), href: referential_line_path(referential, lines.first))
        expect(page).not_to have_link(I18n.t('actions.add'), href: new_referential_line_path(referential))
      end

      context 'filtering' do
        it 'supports filtering by name' do
          fill_in 'q[name_or_number_or_objectid_cont]', with: lines.first.name
          click_button 'search-btn'
          expect(page).to have_content(lines.first.name)
          expect(page).not_to have_content(lines.last.name)
        end

        it 'supports filtering by number' do
          fill_in 'q[name_or_number_or_objectid_cont]', with: lines.first.number
          click_button 'search-btn'
          expect(page).to have_content(lines.first.name)
          expect(page).not_to have_content(lines.last.name)
        end

        it 'supports filtering by objectid' do
          fill_in 'q[name_or_number_or_objectid_cont]', with: lines.first.objectid
          click_button 'search-btn'
          expect(page).to have_content(lines.first.name)
          expect(page).not_to have_content(lines.last.name)
        end
      end
    end

    describe "show" do
      it "displays line" do
        visit line_referential_line_path(line_referential, lines.first)
        expect(page).to have_content(lines.first.name)
      end
    end

    # Fixme #1780
    # describe "new" do
    #   it "creates line and return to show" do
    #     visit line_referential_lines_path(line_referential)
    #     click_link "Ajouter une ligne"
    #     fill_in "line_name", :with => "Line 1"
    #     fill_in "Numéro d'enregistrement", :with => "1"
    #     fill_in "Identifiant Neptune", :with => "chouette:test:Line:999"
    #     click_button("Créer ligne")
    #     expect(page).to have_content("Line 1")
    #   end
    # end

    # Fixme #1780
    # describe "new with group of line", :js => true do
    #   it "creates line and return to show" do
    #     visit new_line_referential_line_path(line_referential)
    #     fill_in "line_name", :with => "Line 1"
    #     fill_in "Numéro d'enregistrement", :with => "1"
    #     fill_in "Identifiant Neptune", :with => "test:Line:999"
    #     fill_in_token_input('line_group_of_line_tokens', :with => "#{group_of_line.name}")
    #     find_button("Créer ligne").trigger("click")
    #     expect(page).to have_text("Line 1")
    #     expect(page).to have_text("#{group_of_line.name}")
    #   end
    # end

    # Fixme #1780
    # describe "edit and return to show" do
    #   it "edit line" do
    #     visit line_referential_line_path(line_referential, subject)
    #     click_link "Editer cette ligne"
    #     fill_in "line_name", :with => "Line Modified"
    #     fill_in "Numéro d'enregistrement", :with => "test-1"
    #     click_button("Editer ligne")
    #     expect(page).to have_content("Line Modified")
    #   end
    # end

  end
end
