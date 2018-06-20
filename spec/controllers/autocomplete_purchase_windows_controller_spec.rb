require 'rails_helper'

RSpec.describe AutocompletePurchaseWindowsController, type: :controller do
  login_user

  let(:referential) { Referential.first }
  let!(:window) { create :purchase_window, name: 'écolà militaire' }

  describe 'GET #index' do
    it 'should be unauthorized' do
      expect { get(:index, referential_id: referential.id) }.to raise_error(FeatureChecker::NotAuthorizedError)
    end

    with_feature "purchase_windows" do
      let(:request){ get(:index, referential_id: referential.id) }
      before do
        request
      end

      it 'should be successful' do
        expect(response).to be_success
      end

      context 'search by name' do
        let(:request){ get :index, referential_id: referential.id, q: {name_or_objectid_cont_any: 'écolà'}, :format => :json }
        it 'should be successful' do
          expect(response).to be_success
          expect(assigns(:purchase_windows)).to eq([window])
        end
      end
    end
  end
end
