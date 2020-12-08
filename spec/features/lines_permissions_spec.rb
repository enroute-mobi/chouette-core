# -*- coding: utf-8 -*-

describe "Lines", :type => :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first') do
        line
      end
    end
  end

  before do
    context.line_referential.organisations << first_organisation
  end

  let(:workbench) { context.workbench }
  let(:line) { context.line }

  context 'permissions' do
    before do
      allow_any_instance_of(LinePolicy).to receive(:create?).and_return permission
      allow_any_instance_of(LinePolicy).to receive(:update?).and_return permission

      visit path
    end

    context 'on index view' do
      let(:path) { workbench_line_referential_lines_path(workbench) }

      context 'if present' do
        let(:permission) { true }

        it 'displays the corresponding button' do
          expected_href = new_workbench_line_referential_line_path(workbench)
          expect(page).to have_link('Ajouter une ligne', href: expected_href)
        end
      end

      context 'if absent' do
        let(:permission) { false }

        it 'does not display the corresponding button' do
          expect(page).not_to have_link('Ajouter une ligne')
        end
      end
    end

    context 'on show view' do
      let(:path) { workbench_line_referential_line_path(workbench, line) }

      context 'if present' do
        let(:permission) { true }

        it 'displays the corresponding buttons' do
          expected_href = edit_workbench_line_referential_line_path(workbench, line)
          expect(page).to have_link('Editer', href: expected_href)
        end
      end

      context 'if absent' do
        let(:permission) { false }

        it 'does not display the corresponding button' do
          expect( page ).not_to have_link('Editer')
        end
      end

    end
  end
end
