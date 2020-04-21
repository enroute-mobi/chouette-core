# -*- coding: utf-8 -*-

describe "PurchaseWindows", :type => :feature do
  login_user

  before do
    @user.organisation.update features: %w{purchase_windows}
  end

  let(:purchase_window) { create :purchase_window}

  describe 'permissions' do
    before do
      allow_any_instance_of(PurchaseWindowPolicy).to receive(:create?).and_return permission
      allow_any_instance_of(PurchaseWindowPolicy).to receive(:destroy?).and_return permission
      allow_any_instance_of(PurchaseWindowPolicy).to receive(:update?).and_return permission
      visit path
    end

    context 'on show view' do
      let( :path ){ referential_purchase_window_path(first_referential, purchase_window) }

      context 'if present → ' do
        let( :permission ){ true }
        it 'view shows the corresponding buttons' do
          expect(page).to have_content(I18n.t('purchase_windows.actions.edit'))
          expect(page).to have_content(I18n.t('purchase_windows.actions.destroy'))
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }
        it 'view does not show the corresponding buttons' do
          expect(page).not_to have_content(I18n.t('purchase_windows.actions.edit'))
          expect(page).not_to have_content(I18n.t('purchase_windows.actions.destroy'))
        end
      end
    end

    context 'on index view' do
      let( :path ){ referential_purchase_windows_path(first_referential) }

      context 'if present → ' do
        let( :permission ){ true }
        it 'index shows an edit button' do
          expect(page).to have_content(I18n.t('purchase_windows.actions.new'))
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }
        it 'index does not show any edit button' do
          expect(page).not_to have_content(I18n.t('purchase_windows.actions.new'))
        end
      end
    end
  end
end
