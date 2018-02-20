# coding: utf-8

describe 'Workbenches', type: :feature do
  login_user

  let(:line_referential) { create :line_referential }
  let(:workbench) { create :workbench, line_referential: line_referential, organisation: @user.organisation }
  # let!(:line) { create :line, line_referential: line_referential }

  # let(:referential_metadatas) { Array.new(2) { |i| create :referential_metadata, lines: [line] } }

  describe 'permissions' do
    before do
      allow_any_instance_of(ReferentialPolicy).to receive(:create?).and_return permission
      visit path
    end

    context 'on show view' do
      let( :path ){ workbench_path(workbench) }

      context 'if present → ' do
        let( :permission ){ true }

        it 'shows the corresponding button' do
          expected_href = new_workbench_referential_path(workbench)
          expect( page ).to have_link('Créer', href: expected_href)
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }

        it 'does not show the corresponding button' do
          expect( page ).not_to have_link('Créer')
        end
      end
      # let!(:ready_referential) { create :referential, workbench: workbench, metadatas: referential_metadatas, ready: true, organisation: @user.organisation }
      # let!(:unready_referential) { create :referential, workbench: workbench }

    end
  end
end
