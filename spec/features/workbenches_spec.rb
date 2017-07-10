
describe 'Workbenches', type: :feature do
  login_user

  before do
    @user.organisation = organisation
  end

  let( :organisation ){ build_stubbed :organisation }

  let(:line_ref) { build_stubbed :line_referential }
  let(:line) { build_stubbed :line, line_referential: line_ref }
  let(:ref_metadata) { build_stubbed(:referential_metadata, lines: [line]) }

  let!(:workbench) { build_stubbed(:workbench, line_referential: line_ref, organisation: organisation) }
  let!(:referential) { build_stubbed :referential, workbench: workbench, metadatas: [ref_metadata], organisation: @user.organisation }

  describe 'show' do
    context 'ready' do
      it 'should show ready referentials', :wip do
        visit workbench_path(workbench)
        expect(page).to have_content(referential.name)
      end

      it 'should not show unready referentials' do
        referential.update_attribute(:ready, false)
        visit workbench_path(workbench)
        expect(page).to_not have_content(referential.name)
      end
    end

    context 'filtering' do
      let(:another_organisation) { create :organisation }
      let(:another_line) { create :line, line_referential: line_ref }
      let(:another_ref_metadata) { create(:referential_metadata, lines: [another_line]) }
      let!(:other_referential) { create :referential, workbench: workbench, metadatas: [another_ref_metadata], organisation: another_organisation}

      before(:each) do
        visit workbench_path(workbench)
      end

      context 'without any filter' do
        it 'should have results' do
          click_button 'Filtrer'
          expect(page).to have_content(referential.name)
          expect(page).to have_content(other_referential.name)
        end
      end

      context 'filter by organisation' do
        it 'should be possible to filter by organisation' do
          find("#q_organisation_name_eq_any_#{@user.organisation.name.parameterize.underscore}").set(true)
          click_button 'Filtrer'

          expect(page).to have_content(referential.name)
          expect(page).not_to have_content(other_referential.name)
        end

        it 'should be possible to filter by multiple organisation' do
          find("#q_organisation_name_eq_any_#{@user.organisation.name.parameterize.underscore}").set(true)
          find("#q_organisation_name_eq_any_#{another_organisation.name.parameterize.underscore}").set(true)
          click_button 'Filtrer'

          expect(page).to have_content(referential.name)
          expect(page).to have_content(other_referential.name)
        end

        it 'should keep filter value on submit' do
          box = "#q_organisation_name_eq_any_#{another_organisation.name.parameterize.underscore}"
          find(box).set(true)
          click_button 'Filtrer'
          expect(find(box)).to be_checked
        end
      end

      context 'filter by status' do
        it 'should display archived referentials' do
          other_referential.update_attribute(:archived_at, Date.today)
          find("#q_archived_at_not_null").set(true)

          click_button 'Filtrer'
          expect(page).to have_content(other_referential.name)
          expect(page).to_not have_content(referential.name)
        end

        it 'should display both archived and unarchived referentials' do
          other_referential.update_attribute(:archived_at, Date.today)
          find("#q_archived_at_not_null").set(true)
          find("#q_archived_at_null").set(true)

          click_button 'Filtrer'
          expect(page).to have_content(referential.name)
          expect(page).to have_content(other_referential.name)
        end

        it 'should display unarchived referentials' do
          other_referential.update_attribute(:archived_at, Date.today)
          find("#q_archived_at_null").set(true)

          click_button 'Filtrer'
          expect(page).to have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should keep filter value on submit' do
          find("#q_archived_at_null").set(true)
          click_button 'Filtrer'
          expect(find("#q_archived_at_null")).to be_checked
        end
      end

      context 'filter by validity period' do
        def fill_validity_field date, field
          select date.year,  :from => "q[validity_period][#{field}(1i)]"
          select I18n.t("date.month_names")[date.month], :from => "q[validity_period][#{field}(2i)]"
          select date.day,   :from => "q[validity_period][#{field}(3i)]"
        end

        it 'should show results for referential in range' do
          dates = referential.validity_period.to_a
          fill_validity_field dates[0], 'begin_gteq'
          fill_validity_field dates[1], 'end_lteq'
          click_button 'Filtrer'

          expect(page).to have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should keep filtering on sort' do
          dates = referential.validity_period.to_a
          fill_validity_field dates[0], 'begin_gteq'
          fill_validity_field dates[1], 'end_lteq'
          click_button 'Filtrer'

          find('a[href*="&sort=validity_period"]').click

          expect(page).to have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should not show results for out off range' do
          fill_validity_field(Date.today - 2.year, 'begin_gteq')
          fill_validity_field(Date.today - 1.year, 'end_lteq')
          click_button 'Filtrer'

          expect(page).to_not have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should keep value on submit' do
          dates = referential.validity_period.to_a
          ['begin_gteq', 'end_lteq'].each_with_index do |field, index|
            fill_validity_field dates[index], field
          end
          click_button 'Filtrer'

          ['begin_gteq', 'end_lteq'].each_with_index do |field, index|
            expect(find("#q_validity_period_#{field}_3i").value).to eq dates[index].day.to_s
            expect(find("#q_validity_period_#{field}_2i").value).to eq dates[index].month.to_s
            expect(find("#q_validity_period_#{field}_1i").value).to eq dates[index].year.to_s
          end
        end
      end

      context 'permissions' do
        before(:each) do
          visit workbench_path(workbench)
        end

        context 'user has the permission to create referentials' do
          it 'shows the link for a new referetnial' do
            expect(page).to have_link(I18n.t('actions.add'), href: new_referential_path(workbench_id: workbench.id))
          end
        end

        context 'user does not have the permission to create referentials' do
          it 'does not show the clone link for referential' do
            @user.update_attribute(:permissions, [])
            visit referential_path(referential)
            expect(page).not_to have_link(I18n.t('actions.add'), href: new_referential_path(workbench_id: workbench.id))
          end
        end
      end

      describe 'create new Referential' do
        it "create a new Referential with a specifed line and period" do
          referential.destroy

          visit workbench_path(workbench)
          click_link I18n.t('actions.add')
          fill_in "referential[name]", with: "Referential to test creation"
          select workbench.lines.first.id, from: 'referential[metadatas_attributes][0][lines][]'

          click_button "Valider"
          expect(page).to have_css("h1", text: "Referential to test creation")
        end
      end
    end
  end
end
