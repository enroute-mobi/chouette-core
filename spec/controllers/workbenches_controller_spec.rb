# frozen_string_literal: true

RSpec.describe WorkbenchesController, type: :controller do
  login_user

  describe "GET show" do
    it "returns http success" do
      get :show, params: { id: current_workbench.id }
      expect(response).to have_http_status(200)
    end
  end

  describe 'DELETE delete_referentials' do
    let(:permissions) { %w[referentials.destroy] }
    let(:referential) { create(:referential, workbench: current_workbench, organisation: organisation) }
    let(:request) do
      delete :delete_referentials, params: { id: current_workbench.id, referentials: [referential.id] }
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
end
