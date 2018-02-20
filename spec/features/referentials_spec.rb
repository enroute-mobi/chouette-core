describe "Referentials", :type => :feature do
  login_user

  let(:referential) { Referential.first }

  describe "index" do

    # FIXME #823
    # it "should support no referential" do
    #   visit referentials_path
    #   expect(page).to have_content("Jeux de Données")
    # end

    context "when several referentials exist" do

      def retrieve_referential_by_slug( slug)
        @user.organisation.referentials.find_by_slug(slug) ||
          create(:referential, :slug => slug, :name => slug, :organisation => @user.organisation)
      end

      let!(:referentials) { [ retrieve_referential_by_slug("aa"),
                              retrieve_referential_by_slug("bb")] }

      # FIXME #823
      # it "should show n referentials" do
      #   visit referentials_path
      #   expect(page).to have_content(referentials.first.name)
      #   expect(page).to have_content(referentials.last.name)
      # end

    end

  end

  describe "show" do
    before(:each) { visit referential_path(referential) }

    it "displays referential" do
      expect(page).to have_content(referential.name)
    end

    context 'archived referential' do
      it 'link to edit referetnial is not displayed' do
        referential.archive!
        visit referential_path(referential)
        expect(page).not_to have_link(I18n.t('actions.edit'), href: edit_referential_path(referential))
      end
    end

    context 'unarchived referential' do
      it 'link to edit referetnial is displayed' do
        expect(page).to have_link(I18n.t('actions.edit'), href: edit_referential_path(referential))
      end
    end

    context 'user has the permission to create referentials' do
      it 'shows the clone link for referetnial' do
        expect(page).to have_link(I18n.t('actions.clone'), href: new_workbench_referential_path(referential.workbench, from: referential.id))
      end
    end

    context 'user does not have the permission to create referentials' do
      it 'does not show the clone link for referetnial' do
        @user.update_attribute(:permissions, [])
        visit referential_path(referential)
        expect(page).not_to have_link(I18n.t('actions.clone'), href: new_workbench_referential_path(referential.workbench, from: referential.id))
      end
    end

    context 'user has the permission to edit referentials' do
      it 'shows the link to edit the referential' do
        expect(page).to have_link(I18n.t('actions.edit'), href: edit_referential_path(referential))
      end

      it 'shows the link to archive the referential' do
        expect(page).to have_link(I18n.t('actions.archive'), href: archive_referential_path(referential))
      end
    end

    context 'user does not have the permission to edit referentials' do
      before(:each) do
        @user.update_attribute(:permissions, [])
        visit referential_path(referential)
      end

      it 'does not show the link to edit the referential' do
        expect(page).not_to have_link(I18n.t('actions.edit'), href: edit_referential_path(referential))
      end

      it 'does not show the link to archive the referential' do
        expect(page).not_to have_link(I18n.t('actions.archive'), href: archive_referential_path(referential))
      end
    end

    context 'user has the permission to destroy referentials' do
      it 'shows the link to destroy the referential' do
        expect(page).to have_link(I18n.t('actions.destroy'), href: referential_path(referential))
      end
    end

    context 'user does not have the permission to destroy referentials' do
      it 'does not show the destroy link for referetnial' do
        @user.update_attribute(:permissions, [])
        visit referential_path(referential)
        expect(page).not_to have_link(I18n.t('actions.destroy'), href: referential_path(referential))
      end
    end
  end

  describe "create" do
    let(:workbench){ @user.organisation.workbenches.last }
    it "should" do
      visit new_workbench_referential_path(workbench)
      fill_in "Nom", :with => "Test"
      click_button "Valider"

      expect(Referential.where(:name => "Test")).not_to be_nil
      # CREATE SCHEMA
    end

  end

  describe "new_from" do
    # let(:cloning)
    let(:worker) { ReferentialCloningWorker.new }

    let(:line) { create(:line_with_stop_areas) }
    let(:jp) { create(:journey_pattern, route: line.routes.first) }
    let(:tt) { create(:time_table) }
    let(:vj) { create(:vehicle_journey, journey_pattern: jp, time_table: tt) }
    let(:ref_metadata) { create(:referential_metadata, lines: [line], referential: referential) }

    context "when user is from the same organisation" do

      xit "should" do
        visit new_workbench_referential_path(referential.workbench, from: referential.id, current_workbench_id: @user.organisation.workbenches.first.id)

        select "2018", :from => "referential_metadatas_attributes_0_periods_attributes_0_begin_1i"

        select "2018", :from => "referential_metadatas_attributes_0_periods_attributes_0_end_1i"

        click_button "Valider"

        clone = Referential.where(name: "Copie de first")

        expect(clone.lines).to include(line)
        expect(clone.lines.first.routes).to match_array(referential.lines.first.routes)

        clone_jp = clone.lines.first.routes.first.journey_patterns
        expect(clone_jp).to include(jp)

        clone_vj = clone.lines.first.routes.first.journey_patterns.first.vehicle_journeys
        expect(clone_vj).to include(vj)

        clone_tt = clone.lines.first.routes.first.journey_patterns.first.vehicle_journeys.first.time_tables
        expect(clone_tt).to include(tt)
      end

      # it "should have the lines from source" do
      #   expect(clone.lines).to include(line)
      # end
      #
      # it "should have the routes from source" do
      #   expect(clone.lines.first.routes).to match_array(referential.lines.first.routes)
      # end
      #
      # it "should have the journey patterns from source" do
      #   clone_jp = clone.lines.first.routes.first.journey_patterns
      #   expect(clone_jp).to include(jp)
      # end
      #
      # it "should have the vehicle journeys from source" do
      #   clone_vj = clone.lines.first.routes.first.journey_patterns.first.vehicle_journeys
      #   expect(clone_vj).to include(vj)
      # end
      #
      # it "should have the timetables from source" do
      #   clone_tt = clone.lines.first.routes.first.journey_patterns.first.vehicle_journeys.first.time_tables
      #   expect(clone_tt).to include(tt)
      # end
    end

    # context "when user is from another organisation" do
    #   before :each do
    #
    #   end
    # end
  end

  describe "destroy" do
    let(:workbench){ @user.organisation.workbenches.last }
    let(:referential) {  create(:referential, :organisation => @user.organisation, workbench: workbench) }

    it "should remove referential" do
      visit referential_path(referential)
      #click_link "Supprimer"
      #expect(Referential.where(:slug => referential.slug)).to be_blank
    end

  end

end
