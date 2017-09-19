RSpec.describe Api::V1::IbooController, type: :controller do
  context '#authenticate' do
    include_context 'iboo authenticated api user'

    it 'should set current organisation' do
      controller.send(:authenticate)
      expect(assigns(:current_organisation)).to eq api_key.organisation
    end
  end
end
