RSpec.describe StopAreaReferentialsController, :type => :controller do
  login_user

  let(:context) do
    Chouette.create do
      workgroup do
        workbench organisation: Organisation.find_by_code('first')
      end
    end
  end
  let(:workbench) { context.workbench }

  describe 'PUT sync' do
    let(:request){ put :sync, params: { workbench_id: workbench.id }}

    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "stop_area_referentials.synchronize" do
      it 'returns HTTP success' do
        expect(request).to redirect_to [ workbench, :stop_area_referential ]
      end
    end
  end
end
