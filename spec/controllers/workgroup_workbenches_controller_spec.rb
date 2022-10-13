RSpec.describe WorkgroupWorkbenchesController, type: :controller do
  login_user

  # TODO: change this with ChouetteFactory
  let(:workbench) { create :workbench, organisation: @user.organisation }
  let(:other_orga) { create :organisation }

  describe 'GET show' do
    context "when user's organisation is in the workgroup organisations list" do
      it 'should respond with a 200' do
        get :show, params: { workgroup_id: workbench.workgroup_id, id: workbench.id }
        expect(response).to have_http_status(200)
      end
    end

    context 'when user is not in the workgroup organisations list' do
      before do
        allow(@user).to receive(:organisation_id) { other_orga.id }
      end
      it 'should respond with a 200' do
        get :show, params: { workgroup_id: workbench.workgroup_id, id: workbench.id }
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'PATCH update' do
    let(:workbench_params) do
      {
        name: 'new workbench name',
        restrictions: ['referentials.flag_urgent']
      }
    end
    let(:request) do
      patch :update, params: {
        workgroup_id: workbench.workgroup_id,
        id: workbench.id,
        workbench: workbench_params
      }
    end

    without_permission 'workbenches.update' do
      it 'should respond with 403' do
        expect(request).to have_http_status 403
      end
    end

    with_permission 'workbenches.update' do
      it 'should respond with 403' do
        expect(request).to have_http_status 403
      end

      context "when user is the workgroup's owner" do
        before do
          workbench.workgroup.owner = @user.organisation
          workbench.workgroup.save!
        end

        it 'returns HTTP success' do
          expect(request).to redirect_to [workbench.workgroup, workbench]
          expect(workbench.reload.name).to eq 'new workbench name'
          expect(workbench.restrictions).to eq ['referentials.flag_urgent']
        end

        context 'when params contains organisation_id' do
          # TODO: change this with ChouetteFactory
          let(:workbench_params) { { organisation_id: Organisation.last.id } }

          it "doesn't change the Workbench organisation" do
            expect { request }.to_not(change { workbench.reload.organisation_id })
          end
        end
      end
    end
  end
end
