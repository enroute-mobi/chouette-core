
RSpec.describe Api::V1::WorkbenchController, type: :controller do
  context '#authenticate' do
    include_context 'iboo authenticated api user'

    it 'should set current workbench' do
      controller.send(:authenticate)
      expect(assigns(:current_workbench)).to eq api_key.workbench
    end
  end
end
