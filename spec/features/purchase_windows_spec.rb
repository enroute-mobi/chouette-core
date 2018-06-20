describe "PurchaseWindows", type: :feature do
  login_user

  before do
    @user.organisation.update features: %w{purchase_windows}
  end

  describe "#index" do
    with_permissions('purchase_windows.create') do
      it "allows users to create new purchase windows" do
        name = 'Test purchase window create'

        visit(referential_purchase_windows_path(first_referential.id))

        click_link(I18n.t('purchase_windows.actions.new'))

        fill_in('purchase_window[name]', with: name)
        click_link(I18n.t('simple_form.labels.purchase_window.add_a_date_range'))
        find(:css, "[name*='[begin(3i)]']").set("1")
        find(:css, "[name*='[begin(2i)]']").set("1")
        find(:css, "[name*='[begin(1i)]']").set("2000")

        find(:css, "[name*='[end(3i)]']").set("1")
        find(:css, "[name*='[end(2i)]']").set("1")
        find(:css, "[name*='[end(1i)]']").set("2001")

        # select('#DD2DAA', from: 'purchase_window[color]')

        click_link(I18n.t('simple_form.labels.purchase_window.add_a_date_range'))
        click_button(I18n.t('actions.submit'))

        expect(page).to have_content(name)
      end
    end

    with_permissions('purchase_windows.update') do
      it "allows users to update purchase windows" do
        actual_name = 'Existing purchase window'
        expected_name = 'Updated purchase window'
        create(
          :purchase_window,
          name: actual_name
        )

        visit(referential_purchase_windows_path(first_referential.id))

        click_link(actual_name)

        click_link(I18n.t('purchase_windows.actions.edit'))
        fill_in('purchase_window[name]', with: expected_name)

        click_button(I18n.t('actions.submit'))

        expect(page).to have_content(expected_name)
      end
    end

    with_permissions('purchase_windows.destroy') do
      it "allows users to destroy purchase windows" do
        name = 'Existing purchase window'
        create(
          :purchase_window,
          name: name
        )

        visit(referential_purchase_windows_path(first_referential.id))

        click_link(name)

        click_link(I18n.t('purchase_windows.actions.destroy'))

        expect(page).to_not have_content(name)
      end
    end
  end
end
