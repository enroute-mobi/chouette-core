# frozen_string_literal: true

RSpec.describe LineNoticeMembershipsCollectionsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          line_provider :line_provider
          line :line
          line_notice :line_notice1, lines: [:line]
          line_notice :line_notice2, lines: [:line]
          line_notice :other_line_notice
        end
        workbench(organisation: organisation) do
          line_provider :other_line_provider
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation) do
          line :other_line
        end
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:line_referential) { workbench.line_referential }
  let(:line) { context.line(:line) }
  let(:line_notice1) { context.line_notice(:line_notice1) }
  let(:other_line_notice) { context.line_notice(:other_line_notice) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s, 'line_id' => line.id.to_s } }

  before { @user.update(permissions: %w[lines.update line_notice_memberships.create line_notice_memberships.destroy]) }

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params }

    before { request }

    it { is_expected.to render_template('line_notice_memberships_collections/edit') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line is not in current workbench line referential' do
      let(:line) { context.line(:other_line) }
      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge(
        { 'line' => { 'line_notice_ids' => [line_notice1, other_line_notice].map(&:id).join(',') } }
      )
    end

    before { request }

    it { expect { line.reload }.to change { line.line_notices }.to(match_array([line_notice1, other_line_notice])) }

    it 'redirects to line line notices path' do
      expect(response).to redirect_to workbench_line_referential_line_line_notice_memberships_path(workbench, line)
    end

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line is not in current workbench line referential' do
      let(:line) { context.line(:other_line) }
      it { expect(response).to have_http_status(:not_found) }
    end
  end
end
