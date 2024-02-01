# frozen_string_literal: true

RSpec.describe StopAreasController, type: :controller do
  login_user permissions: []

  let(:context) do
    Chouette.create do
      workbench(organisation: Organisation.find_by(code: 'first')) do
        stop_area
      end
    end
  end
  let(:workbench) { context.workbench }

  describe 'GET index' do
    subject(:request) { get :index, params: { workbench_id: workbench.id.to_s } }

    it 'calls set_current_workgroup' do
      expect(controller).to receive(:set_current_workgroup)
      subject
    end
  end
end
