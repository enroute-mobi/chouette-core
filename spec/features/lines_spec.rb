# coding: utf-8
describe "Lines", type: :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        3.times { line }
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:lines) { context.line_referential.lines }
  let(:other_line) { lines.last }
  subject { lines.first }

  with_permissions "boiv:read" do
    describe "index" do
      before(:each) { visit workbench_line_referential_lines_path(workbench) }

      it "displays lines" do
        expect(page).to have_content(subject.name)
        expect(page).to have_content(other_line.name)
      end

      it 'allows only R in CRUD' do
        expect(page).to have_link(I18n.t('actions.show'))
        expect(page).not_to have_link(I18n.t('actions.edit'), href: edit_workbench_line_referential_line_path(workbench, subject))
        expect(page).not_to have_link(I18n.t('actions.destroy'), href: workbench_line_referential_line_path(workbench, subject))
        expect(page).not_to have_link(I18n.t('actions.add'), href: new_workbench_line_referential_line_path(workbench))
      end

      context 'filtering' do
        it 'supports filtering by name' do
          fill_in 'q[name_or_number_or_short_id_cont]', with: subject.name
          click_button 'search-btn'
          expect(page).to have_content(subject.name)
          expect(page).not_to have_content(other_line.name)
        end

        it 'supports filtering by number' do
          fill_in 'q[name_or_number_or_short_id_cont]', with: subject.number
          click_button 'search-btn'
          expect(page).to have_content(subject.name)
          expect(page).not_to have_content(other_line.name)
        end

        it 'supports filtering by objectid' do
          fill_in 'q[name_or_number_or_short_id_cont]', with: subject.get_objectid.short_id
          click_button 'search-btn'
          expect(page).to have_content(subject.name)
          expect(page).not_to have_content(other_line.name)
        end

        context "when filtered by status" do
          it 'supports displaying only activated lines' do
            subject.update_attribute(:deactivated, true)
            other_line.update_attribute(:deactivated, false)

            find('#q_status_activated').set(true)
            click_button 'search-btn'
            expect(page).to_not have_content(subject.name)
            expect(page).to have_content(other_line.name)
          end

          it 'supports displaying only deactivated lines' do
            subject.update_attribute(:deactivated, true)
            other_line.update_attribute(:deactivated, false)

            find('#q_status_deactivated').set(true)
            click_button 'search-btn'
            expect(page).to have_content(subject.name)
            expect(page).to_not have_content(other_line.name)
          end

          it 'supports displaying all lines ' do
            subject.update_attribute(:deactivated, true)
            other_line.update_attribute(:deactivated, false)

            find('#q_status_all').set(true)
            click_button 'search-btn'
            expect(page).to have_content(subject.name)
            expect(page).to have_content(other_line.name)
          end
        end
      end
    end

    describe "show" do
      it "displays line" do
        visit workbench_line_referential_line_path(workbench, subject)
        expect(page).to have_content(subject.name)
      end
    end

  end
end
