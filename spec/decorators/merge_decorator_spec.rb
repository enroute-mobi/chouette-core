RSpec.describe MergeDecorator, type: [:helper, :decorator] do
  include Support::DecoratorHelpers

  let( :workbench ){ build_stubbed :workbench }
  let( :object ){ build_stubbed :merge, workbench: workbench, new: referential }
  let( :referential ){ build_stubbed :referential, workbench: workbench }
  let( :user ){ build_stubbed :user }
  let( :current_merge) { true }
  let(:context){
    { workbench: workbench }
  }

  before(:each){
    allow(object).to receive(:current?){ current_merge }
  }
  describe 'action links for' do
    context "on show" do
      let( :action){ :show }
      it 'has corresponding actions' do
        expect_action_link_elements(action).to eq []
        expect_action_link_hrefs(action).to eq([])
      end

      context 'with a successful merge' do
        before(:each){
          object.status = :successful
        }

        it 'has corresponding actions' do
          expect_action_link_elements(action).to eq ["Voir l'offre associée"]
          expect_action_link_hrefs(action).to eq([referential_path(object)])
        end

        context 'with a non-current merge' do
          let( :current_merge) { false }

          it 'has corresponding actions' do
            expect_action_link_elements(action).to eq ["Voir l'offre associée"]
            expect_action_link_hrefs(action).to eq([referential_path(object)])
          end

          context "in the right organisation" do
            before(:each) do
              object.workbench.organisation = user.organisation
            end

            it 'has corresponding actions' do
              expect_action_link_elements(action).to eq ["Voir l'offre associée"]
              expect_action_link_hrefs(action).to eq([referential_path(object)])
            end

            context 'with the rollback permission' do
              before(:each) do
                user.permissions = %w(merges.rollback)
              end

              it 'has corresponding actions' do
                expect_action_link_elements(action).to eq ['Revenir à cette offre',"Voir l'offre associée"]
                expect_action_link_hrefs(action).to eq([rollback_workbench_merge_path(workbench, object),referential_path(object)])
              end
            end
          end
        end
      end
    end
  end
end
