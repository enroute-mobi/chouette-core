
RSpec.describe WorkbenchesController, :type => :controller do
  login_user

  let(:workbench) { create :workbench, organisation: @user.organisation }
  let(:compliance_control_set) { create :compliance_control_set, organisation: @user.organisation }
  let(:merge_id) { 2**64/2 - 1 } # Let's check we support Bigint

  describe "GET show" do
    it "returns http success" do
      get :show, params: { id: workbench.id }
      expect(response).to have_http_status(200)
    end
  end

  describe 'DELETE delete_referentials' do
    let(:referential) { create(:referential, workbench: workbench, organisation: workbench.organisation) }
    let(:request) do
      delete :delete_referentials, params: { id: workbench.id, referentials: [referential.id] }
    end

    context 'with an active referential' do
      before { referential.active! }

      it 'should schedule a deletion' do
        expect{ request }.to change{ Delayed::Job.count }.by 1
        expect(referential.reload.ready?).to be_falsy
      end
    end

    context 'with a merged referential' do
      before { referential.merged! }

      it 'should do nothing' do
        count = Delayed::Job.count
        expect{ request }.to_not(change { referential.reload.state })
        expect(Delayed::Job.count).to eq count
      end
    end

    context 'with a failed referential' do
      before { referential.failed! }

      it 'should schedule a deletion' do
        expect{ request }.to change{ Delayed::Job.count }.by 1
        expect(referential.reload.ready?).to be_falsy
      end
    end

    context 'with a referential from another workbench' do
      let(:referential) { create(:referential) }

      it 'should do nothing' do
        count = Delayed::Job.count
        expect { request }.to_not(change { referential.reload.state })
        expect(Delayed::Job.count).to eq count
      end
    end
  end

  describe 'PATCH update' do
    let(:workbench_params){
      {
        compliance_control_set_ids: {
          after_import: compliance_control_set.id,
          after_merge: merge_id
        }
      }
    }
    let(:request){ patch :update, params: { id: workbench.id, workbench: workbench_params }}

    without_permission "workbenches.update" do
      it 'should respond with 403' do
        expect(request).to have_http_status 403
      end
    end

    with_permission "workbenches.update" do
      it 'returns HTTP success' do
        expect(request).to redirect_to [workbench]
        expect(workbench.reload.compliance_control_set(:after_import)).to eq compliance_control_set
        # Let's check we support Bigint
        expect(workbench.reload.owner_compliance_control_set_ids["after_merge"]).to eq merge_id.to_s
      end
    end
  end

end
