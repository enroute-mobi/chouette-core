# frozen_string_literal: true

RSpec.describe WorkgroupWorkbenchesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workgroup owner: Organisation.find_by(code: 'first') do
        workbench organisation: Organisation.find_by(code: 'first')
      end
    end
  end
  let(:workbench) { context.workbench }

  describe 'GET show' do
    context "when user is the workgroup's owner" do
      it 'should respond with ok' do
        get :show, params: { workgroup_id: workbench.workgroup_id, id: workbench.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is in the workgroup organisations list' do
      let(:context) do
        Chouette.create do
          workgroup do
            workbench organisation: Organisation.find_by(code: 'first')
          end
        end
      end

      it 'should respond with not found' do
        get :show, params: { workgroup_id: workbench.workgroup_id, id: workbench.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST create' do
    let(:workbench_params) do
      {
        name: 'new workbench name',
        current_organisation: ''
      }
    end

    let(:request) do
      post :create, params: { workgroup_id: workbench.workgroup_id.to_s, workbench: workbench_params }
    end

    before { workbench } # to init all objects first

    it 'creates a new workbench without organisation' do
      expect { request }.to change { Workbench.count }.by(1)
      expect(Workbench.last).to have_attributes(
        name: 'new workbench name',
        organisation_id: nil
      )
    end

    context 'with "in our own organisation"' do
      let(:workbench_params) do
        {
          name: 'new workbench name',
          current_organisation: '1'
        }
      end

      it 'creates a new workbench with current organisation' do
        expect { request }.to change { Workbench.count }.by(1)
        expect(Workbench.last).to have_attributes(
          name: 'new workbench name',
          organisation_id: Organisation.find_by(code: 'first').id
        )
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
      it 'should respond with forbidden' do
        expect(request).to have_http_status(:forbidden)
      end
    end

    with_permission 'workbenches.update' do
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
          let(:workbench_params) { { organisation_id: Chouette.create { organisation }.organisation } }

          it "doesn't change the Workbench organisation" do
            expect { request }.to_not(change { workbench.reload.organisation_id })
          end
        end
      end

      context 'when user is in the workgroup organisations list' do
        let(:context) do
          Chouette.create do
            workgroup do
              workbench organisation: Organisation.find_by(code: 'first')
            end
          end
        end

        it 'should respond with not found' do
          expect(request).to have_http_status(:not_found)
        end
      end
    end
  end
end
