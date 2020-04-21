
RSpec.describe Api::V1::WorkbenchesController, type: :controller do
  context 'unauthenticated' do
    include_context 'iboo wrong authorisation api user'

    describe 'GET #index' do
      it 'should not be successful' do
        get :index, params: { format: :json }
        expect(response).not_to be_successful
      end
    end
  end

  context 'authenticated' do
    include_context 'iboo authenticated api user'

    describe 'GET #index' do
      it 'should be successful' do
        get :index, params: { format: :json }
        expect(response).to be_successful
      end

      it 'should only return the current organisation workbench' do
        create(:workbench)

        get :index, params: { format: :json }
        expect(assigns(:workbenches).length).to eq 1
      end
    end
  end
end
