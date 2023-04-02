RSpec.describe 'Workbenches', type: :feature do
  login_user
  let(:workgroup) { create :workgroup, owner: @user.organisation }

  let(:line_ref) { workgroup.line_referential }
  let(:line) { create :line, line_referential: line_ref, referential: referential }
  let(:ref_metadata) { create(:referential_metadata) }

  let!(:workbench) { create(:workbench, name: "Test", line_referential: line_ref, organisation: @user.organisation, workgroup: workgroup) }
  let!(:referential) { create :workbench_referential, workbench: workbench, metadatas: [ref_metadata], organisation: @user.organisation }

  before(:each) do
    ref_metadata.update lines: [line]
  end

  describe 'show' do
    context 'ready' do
      it 'should show ready referentials' do
        visit workbench_path(workbench)
        expect(page).to have_content(referential.name)
      end

      it 'should show unready referentials' do
        referential.update_attribute(:ready, false)
        visit workbench_path(workbench)
        expect(page).to have_content(referential.name)
      end
    end

    it 'lists referentials in the current workgroup' do
      other_workbench = create(
        :workbench,
        line_referential: line_ref,
        workgroup: workbench.workgroup
      )
      other_referential = create(
        :workbench_referential,
        workbench: other_workbench,
        organisation: other_workbench.organisation,
        metadatas: []
      )

      other_referential_metadata = create(
        :referential_metadata,
        lines: [create(:line, line_referential: line_ref, referential: referential)]
      )

      other_referential.metadatas = [other_referential_metadata]
      other_referential.save

      # We can see referentials in the same workgroup,
      # and containing lines associated to the workbench

      hidden_referential = create(
        :workbench_referential,
        workbench: create(
          :workbench,
          line_referential: line_ref
        ),
        metadatas: [
          create(
            :referential_metadata,
            lines: [create(:line, line_referential: line_ref)]
          )
        ]
      )

      visit workbench_path(workbench)

      expect(page).to have_content(referential.name),
        "Couldn't find `referential`: `#{referential.inspect}`"
      # expect(page).to have_content(other_referential.name),
      #   "Couldn't find `other_referential`: `#{other_referential.inspect}`"
      expect(page).to_not have_content(other_referential.name),
       "Couldn't find `other_referential`: `#{other_referential.inspect}`"
      expect(page).to_not have_content(hidden_referential.name),
        "Couldn't find `hidden_referential`: `#{hidden_referential.inspect}`"
    end

    it "prevents pending referentials from being selected" do
      line = create(:line, line_referential: line_ref, referential: referential)
      metadata = create(:referential_metadata, lines: [line])
      pending_referential = create(
        :workbench_referential,
        workbench: workbench,
        metadatas: [metadata],
        organisation: @user.organisation,
        ready: false
      )
      pending_referential.pending!

      visit workbench_path(workbench)

      expect(
        find("input[type='checkbox'][value='#{referential.id}']")
      ).not_to be_disabled
      expect(
        find("input[type='checkbox'][value='#{pending_referential.id}']")
      ).to be_disabled
    end

    context 'permissions' do
      before(:each) do
        visit workbench_path(workbench)
      end

      context 'user has the permission to create referentials' do
        it 'shows the link for a new referetnial' do
          expect(page).to have_link(I18n.t('actions.new'), href: new_workbench_referential_path(workbench))
        end
      end

      context 'user does not have the permission to create referentials' do
        it 'does not show the clone link for referential' do
          @user.update_attribute(:permissions, [])
          visit referential_path(referential)
          expect(page).not_to have_link(I18n.t('actions.new'), href: new_workbench_referential_path(workbench))
        end
      end
    end

    describe 'create new Referential' do
      #TODO Manage functional_scope
      it "create a new Referential with a specifed line and period" do
        skip "The functional scope for the Line collection causes problems" do
          functional_scope = JSON.generate(Chouette::Line.all.map(&:objectid))
          lines = Chouette::Line.where(objectid: functional_scope)

          @user.organisation.update_attribute(:sso_attributes, { functional_scope: functional_scope } )
          ref_metadata.update_attribute(:line_ids, lines.map(&:id))

          referential.destroy
          visit workbench_path(workbench)
          click_link I18n.t('actions.new')
          fill_in "referential[name]", with: "Referential to test creation"
          select ref_metadata.line_ids.first, from: 'referential[metadatas_attributes][0][lines][]'

          click_button "Valider"
          expect(page).to have_css("h1", text: "Referential to test creation")
        end
      end
    end
  end
end
