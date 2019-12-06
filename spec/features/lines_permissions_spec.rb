# -*- coding: utf-8 -*-

describe "Lines", :type => :feature do
  login_user

  let(:line_referential) { create :line_referential, workgroup: create(:workgroup) }

  let(:network) { create(:network) }
  let(:company) { create(:company) }
  let(:line) { create :line_with_stop_areas, network: network, company: company, line_referential: line_referential }
  context 'permissions' do
    before do
      create :group_of_line
      line_referential.lines << line
      line_referential.organisations << Organisation.first
      allow_any_instance_of(LinePolicy).to receive(:create?).and_return permission
      allow_any_instance_of(LinePolicy).to receive(:destroy?).and_return permission
      visit path
    end

    context 'on index view' do
      let( :path ){ line_referential_lines_path(line_referential) }

      context 'if present → ' do
        let( :permission ){ true }

        it 'displays the corresponding button' do
          expected_href = new_line_referential_line_path(line_referential)
          expect( page ).to have_link('Ajouter une ligne', href: expected_href)
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }

        it 'does not display the corresponding button' do
          expect( page ).not_to have_link('Ajouter une ligne')
        end
      end
    end

    context 'on show view' do
      skip 'policies always false' do
        let( :path ){ line_referential_line_path(line_referential, line) }

        context 'if present → ' do
          let( :permission ){ true }

          it 'displays the corresponding buttons' do
            expected_href = new_line_referential_line_path(line_referential)
            expect( page ).to have_link('Ajouter une ligne', href: expected_href)
          end
        end

        context 'if absent → ' do
          let( :permission ){ false }

          it 'does not display the corresponding button' do
            expect( page ).not_to have_link('Ajouter une ligne')
          end
        end
      end

    end
  end
end
