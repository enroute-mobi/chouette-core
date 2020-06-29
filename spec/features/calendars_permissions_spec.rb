RSpec.describe 'Calendars', type: :feature do
  login_user

  let(:calendar) { create :calendar, organisation: first_organisation, workgroup: first_workgroup }
  let(:workgroup) { first_workgroup }

  describe 'permissions' do
    before do
      allow_any_instance_of(CalendarPolicy).to receive(:create?).and_return permission
      allow_any_instance_of(CalendarPolicy).to receive(:destroy?).and_return permission
      allow_any_instance_of(CalendarPolicy).to receive(:edit?).and_return permission
      allow_any_instance_of(CalendarPolicy).to receive(:share?).and_return permission
      visit path
    end

    context 'on show view' do
      let( :path ){ workgroup_calendar_path(workgroup, calendar) }

      context 'if present → ' do
        let( :permission ){ true }
        it 'view shows the corresponding buttons' do
          expect(page).to have_css('a.btn.btn-default', text: 'Editer')
          expect(page).to have_css('a.btn.btn-primary', text: 'Supprimer')
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }
        it 'view does not show the corresponding buttons' do
          expect(page).not_to have_css('a.btn.btn-default', text: 'Editer')
          expect(page).not_to have_css('a.btn.btn-primary', text: 'Supprimer')
        end
      end
    end

    context 'on edit view' do
      let( :path ){ edit_workgroup_calendar_path(workgroup, calendar) }

      context 'if present → ' do
        let( :permission ){ true }
        it 'view shows the corresponding checkbox' do
          expect( page ).to have_css('input#calendarshared')
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }
        it 'view does not show the corresponding checkbox' do
          expect( page ).not_to have_css('input#calendarshared')
        end
      end
    end

    context 'on index view' do
      let( :path ){ workgroup_calendars_path(workgroup) }

      context 'if present → ' do
        let( :permission ){ true }
        it 'index shows an edit button' do
          expect(page).to have_css('a.btn.btn-default', text: I18n.t('actions.add'))
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }
        it 'index does not show any edit button' do
          expect(page).not_to have_css('a.btn.btn-default', text: I18n.t('actions.add'))
        end
      end
    end
  end
end
