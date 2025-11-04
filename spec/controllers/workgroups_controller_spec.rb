# frozen_string_literal: true

RSpec.describe WorkgroupsController, type: :controller do
  login_user

  let(:context) do
    organisation = self.organisation
    Chouette.create do
      workgroup owner: organisation do
        workbench organisation: organisation
      end
      workgroup :organisations_workgroup do
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
      let(:workgroup) { context.workgroup(:other_workgroup) }

      it 'should not found the Workgroup' do
        expect(request).to render_template('errors/not_found')
      end

      context 'when the user organisation is among the workgroup organisations' do
        let(:workgroup) { context.workgroup(:organisations_workgroup) }

        it 'should not found the Workgroup' do
          expect(request).to render_template('errors/not_found')
        end
      end
    end
  end

  describe 'PUT #setup_deletion' do
    subject(:request) { put :setup_deletion, params: { id: workgroup } }

    let(:permissions) { %w[workgroups.destroy] }

    it { is_expected.to redirect_to(workgroup_path(workgroup)) }

    it { expect { subject }.to change { workgroup.reload.deleted_at }.from(be_nil).to(be_present) }
  end

  describe 'PUT #remove_deletion' do
    subject(:request) { put :remove_deletion, params: { id: workgroup } }

    let(:permissions) { %w[workgroups.destroy] }

    before { workgroup.setup_deletion! }

    it { is_expected.to redirect_to(workgroup_path(workgroup)) }

    it { expect { subject }.to change { workgroup.reload.deleted_at }.from(be_present).to(be_nil) }
  end
end
