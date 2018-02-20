RSpec.describe 'Workbenches', type: :feature do
  login_user

  let(:line_ref) { create :line_referential }
  let(:line) { create :line, line_referential: line_ref }
  let(:ref_metadata) { create(:referential_metadata, lines: [line]) }

  let!(:workbench) { create(:workbench, line_referential: line_ref, organisation: @user.organisation) }
  let!(:referential) { create :workbench_referential, workbench: workbench, metadatas: [ref_metadata], organisation: @user.organisation }

  describe 'show' do
    context 'ready' do
      it 'should show ready referentials' do
        visit workbench_path(workbench)
        expect(page).to have_content(referential.name)
      end

      it 'should not show unready referentials' do
        referential.update_attribute(:ready, false)
        visit workbench_path(workbench)
        expect(page).to_not have_content(referential.name)
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
        metadatas: [
          create(
            :referential_metadata,
            lines: [create(:line, line_referential: line_ref)]
          )
        ]
      )

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
      expect(page).to have_content(other_referential.name),
        "Couldn't find `other_referential`: `#{other_referential.inspect}`"
      expect(page).to_not have_content(hidden_referential.name),
        "Couldn't find `hidden_referential`: `#{hidden_referential.inspect}`"
    end

    context 'filtering' do
      let!(:another_organisation) { create :organisation }
      let(:another_line) { create :line, line_referential: line_ref }
      let(:another_ref_metadata) { create(:referential_metadata, lines: [another_line]) }
      let(:other_workbench) do
        create(
          :workbench,
          line_referential: line_ref,
          organisation: another_organisation,
          workgroup: workbench.workgroup
        )
      end
      let!(:other_referential) do
        create(
          :workbench_referential,
          workbench: other_workbench,
          metadatas: [another_ref_metadata],
          organisation: other_workbench.organisation
        )
      end


      before(:each) do
        visit workbench_path(workbench)
      end

      context 'without any filter' do
        it 'should have results' do
          click_button I18n.t('actions.filter')
          expect(page).to have_content(referential.name)
          expect(page).to have_content(other_referential.name)
        end
      end

      context 'filter by organisation' do
        it 'should be possible to filter by organisation' do
          find("#q_organisation_name_eq_any_#{@user.organisation.name.parameterize.underscore}").set(true)
          click_button I18n.t('actions.filter')

          expect(page).to have_content(referential.name)
          expect(page).not_to have_content(other_referential.name)
        end

        it 'should be possible to filter by multiple organisation' do
          find("#q_organisation_name_eq_any_#{@user.organisation.name.parameterize.underscore}").set(true)
          find("#q_organisation_name_eq_any_#{other_referential.organisation.name.parameterize.underscore}").set(true)
          click_button I18n.t('actions.filter')

          expect(page).to have_content(referential.name)
          expect(page).to have_content(other_referential.name)
        end

        it 'should keep filter value on submit' do
          box = "#q_organisation_name_eq_any_#{another_organisation.name.parameterize.underscore}"
          find(box).set(true)
          click_button I18n.t('actions.filter')
          expect(find(box)).to be_checked
        end

        it 'only lists organisations in the current workgroup' do
          unaffiliated_workbench = workbench.dup
          unaffiliated_workbench.update(organisation: create(:organisation))

          expect(page).to have_selector(
            "#q_organisation_name_eq_any_#{@user.organisation.name.parameterize.underscore}"
          )
          expect(page).to_not have_selector(
            "#q_organisation_name_eq_any_#{unaffiliated_workbench.name.parameterize.underscore}"
          )
        end
      end

      context 'filter by status' do
        it 'should display archived referentials' do
          other_referential.update_attribute(:archived_at, Date.today)
          find("#q_archived_at_not_null").set(true)

          click_button I18n.t('actions.filter')
          expect(page).to have_content(other_referential.name)
          expect(page).to_not have_content(referential.name)
        end

        it 'should display both archived and unarchived referentials' do
          other_referential.update_attribute(:archived_at, Date.today)
          find("#q_archived_at_not_null").set(true)
          find("#q_archived_at_null").set(true)

          click_button I18n.t('actions.filter')
          expect(page).to have_content(referential.name)
          expect(page).to have_content(other_referential.name)
        end

        it 'should display unarchived referentials' do
          other_referential.update_attribute(:archived_at, Date.today)
          find("#q_archived_at_null").set(true)

          click_button I18n.t('actions.filter')
          expect(page).to have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should keep filter value on submit' do
          find("#q_archived_at_null").set(true)
          click_button I18n.t('actions.filter')
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
          fill_validity_field dates[0], 'start_date'
          fill_validity_field dates[1], 'end_date'
          click_button I18n.t('actions.filter')

          expect(page).to have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should keep filtering on sort' do
          dates = referential.validity_period.to_a
          fill_validity_field dates[0], 'start_date'
          fill_validity_field dates[1], 'end_date'
          click_button I18n.t('actions.filter')

          find('a[href*="&sort=validity_period"]').click

          expect(page).to have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should not show results for out off range' do
          fill_validity_field(Date.today - 2.year, 'start_date')
          fill_validity_field(Date.today - 1.year, 'end_date')
          click_button I18n.t('actions.filter')

          expect(page).to_not have_content(referential.name)
          expect(page).to_not have_content(other_referential.name)
        end

        it 'should keep value on submit' do
          dates = referential.validity_period.to_a
          ['start_date', 'end_date'].each_with_index do |field, index|
            fill_validity_field dates[index], field
          end
          click_button I18n.t('actions.filter')

          ['start_date', 'end_date'].each_with_index do |field, index|
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
            expect(page).to have_link(I18n.t('actions.add'), href: new_workbench_referential_path(workbench))
          end
        end

        context 'user does not have the permission to create referentials' do
          it 'does not show the clone link for referential' do
            @user.update_attribute(:permissions, [])
            visit referential_path(referential)
            expect(page).not_to have_link(I18n.t('actions.add'), href: new_workbench_referential_path(workbench))
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
            click_link I18n.t('actions.add')
            fill_in "referential[name]", with: "Referential to test creation"
            select ref_metadata.line_ids.first, from: 'referential[metadatas_attributes][0][lines][]'

            click_button "Valider"
            expect(page).to have_css("h1", text: "Referential to test creation")
          end
        end
      end
    end
  end
end
