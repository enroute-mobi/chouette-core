RSpec.describe Api::V1::BrowserEnvironmentController do
  describe 'GET #show' do
    subject do
      get :show
      JSON.parse(response.body)
    end

    context "when version is 'dummy'" do
      before do
        allow(Nest::Version).to receive_message_chain(:current, :name).and_return('dummy')
      end
      it { is_expected.to include('version' => 'dummy')}
    end
  end
end
