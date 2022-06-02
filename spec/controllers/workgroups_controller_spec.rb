RSpec.describe WorkgroupsController, :type => :controller do
  login_user

  let(:context) do
    Chouette.create do
      # To match organisation used by login_user
      organisation = Organisation.find_by_code('first')
      workgroup owner: organisation do
        workbench organisation: organisation
      end
      workgroup :other_workgroup
    end
  end

  let(:workgroup) { context.workgroup }

  describe "GET show" do
    subject(:request) { get :show, params: { id: workgroup } }

    it { is_expected.to be_successful }

    context "when workgroup isn't owned" do
      let(:workgroup) { context.workgroup(:other_workgroup)}

      it 'should not found the Workgroup' do
        expect { request }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
