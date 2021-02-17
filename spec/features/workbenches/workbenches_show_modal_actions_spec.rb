RSpec.describe 'Workbenches', type: :feature do
  login_user

  let(:workgroup) { create :workgroup, owner: @user.organisation }
  let(:line_ref) { workgroup.line_referential }
  let(:line) { create :line, line_referential: line_ref, referential: referential }
  let(:ref_metadata) { create(:referential_metadata) }

  let(:workbench) { create :workbench, line_referential: line_ref, organisation: @user.organisation, workgroup: workgroup }
  let!(:referential) { create :workbench_referential,
                              workbench: workbench,
                              metadatas: [ref_metadata],
                              organisation: @user.organisation }

  before(:each) do
    ref_metadata.lines = [line]
    ref_metadata.save
  end

  describe 'show' do
    context 'modal action' do
      it 'expected behavior' do
        visit workbench_path(workbench)

        # Modal Action Box: is present
        within( :css, ".select_toolbox#selected-referentials-action-box span.info-msg > span") do
          expect( page ).to have_content("0")
        end

      end
    end
  end

end
