# frozen_string_literal: true

RSpec.describe SearchesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(:workgroup, owner: organisation) do
        workbench(:workbench, organisation: organisation)
      end
      workgroup :other_workgroup do
        workbench :other_workbench
      end
    end
  end

  describe '#index' do
    let(:parent_resources) { 'imports' }
    let(:params) { { search_parent_id => search_parent, 'parent_resources' => parent_resources } }
    let(:request) { get :index, params: params }

    before { request }

    context 'in workgroup' do
      let(:search_parent_id) { 'workgroup_id' }
      let(:search_parent) { context.workgroup(:workgroup) }

      it { is_expected.to render_template('searches/index') }

      context 'when workgroup is not accessible by user' do
        let(:search_parent) { context.workgroup(:other_workgroup) }

        it { expect(response).to have_http_status(:not_found) }
      end
    end

    context 'in workbench' do
      let(:search_parent_id) { 'workbench_id' }
      let(:search_parent) { context.workbench(:workbench) }

      it { is_expected.to render_template('searches/index') }

      context 'when workbench is not accessible by user' do
        let(:search_parent) { context.workbench(:other_workbench) }

        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end
end
