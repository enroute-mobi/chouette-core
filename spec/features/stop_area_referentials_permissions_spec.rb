# coding: utf-8
RSpec.describe 'StopAreaReferentials', type: :feature do
  login_user

  describe 'permissions' do
    before do
      allow_any_instance_of(StopAreaReferentialPolicy).to receive(:synchronize?).and_return permission
      visit path
    end

    context 'on show view' do
      let(:path) { workbench_stop_area_referential_path(first_workbench) }

      context 'if present → ' do
        let( :permission ){ true }
        it 'shows an edit button' do
          expect(page).to have_css('a.btn.btn-default', text: I18n.t('actions.sync'))
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }
        it 'does not show any edit button' do
          expect(page).not_to have_css('a.btn.btn-default', text: I18n.t('actions.sync'))
        end
      end
    end
  end
end
