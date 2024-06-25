# frozen_string_literal: true

RSpec.describe LineNoticeMembershipsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      organisation = Organisation.find_by(code: 'first')
      workgroup(owner: organisation) do
        workbench(:workbench, organisation: organisation) do
          line_provider :line_provider
          line :line
          line_notice :line_notice, lines: [:line]
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
  let(:line_notice_membership) do
    context.line(:line).line_notice_memberships.detect { |m| m.line_notice_id == context.line_notice(:line_notice).id }
  end

  let(:base_params) { { 'workbench_id' => workbench.id.to_s, 'line_id' => line.id.to_s } }
  let(:base_line_notice_attrs) { { 'title' => 'test' } }
  let(:line_notice_attrs) { base_line_notice_attrs }

  before do
    @user.update(
      permissions: %w[
        lines.update
        line_notices.create
        line_notice_memberships.create line_notice_memberships.destroy
      ]
    )
  end

  describe 'GET #index' do
    let(:context) do
      Chouette.create do
        workgroup(owner: Organisation.find_by(code: 'first')) do
          workbench :workbench, organisation: Organisation.find_by(code: 'first') do
            line_provider(:line_provider) do
              line :line
              line_notice :first, lines: [:line]
              line_notice :second, lines: [:line]
            end
          end
        end
        workgroup(owner: Organisation.find_by(code: 'first')) do
          line_notice :other_line_notice, lines: [:line]
        end
      end
    end

    let(:line_provider) { context.line_provider(:line_provider) }
    let(:line_notices) { line_provider.line_notices }
    let(:other_line_notice) { context.line_notice(:other_line_notice) }

    let(:index_params) { base_params }
    let(:request) { get :index, params: index_params }

    before { request }

    it 'should be successful' do
      expect(response).to be_successful
      expect(assigns(:line_notice_memberships).map(&:line_notice)).to match_array([*line_notices, other_line_notice])
    end

    context 'with filters' do
      context 'on title or content' do
        let(:index_params) { base_params.merge({ q: { title_or_content_cont: line_notices.first.title } }) }

        it 'filters' do
          expect(response).to be_successful
          expect(assigns(:line_notice_memberships).map(&:line_notice)).to match_array([line_notices.first])
        end
      end
    end
  end

  describe 'GET #new' do
    let(:stub_policy) { true }
    let(:request) { get :new, params: base_params }

    before do
      if stub_policy
        fk_policy = double
        expect(fk_policy).to receive(:new?).with(Chouette::LineNotice).and_return(true)
        expect(Policy::Line).to receive(:new).with(line, context: anything).and_return(fk_policy)
      end

      request
    end

    it { is_expected.to render_template('line_notice_memberships/new') }

    context 'when the params contain a line provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'line_notice' => { 'line_provider_id' => line_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { is_expected.to render_template('line_notice_memberships/new') }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        let(:stub_policy) { false }
        it { expect(response).to have_http_status(:not_found) }
      end
    end

    context 'of another workbench' do
      let(:line) { context.line(:other_line) }
      let(:stub_policy) { false }
      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe 'POST #create' do
    let(:stub_policy) { true }
    let(:request) { post :create, params: base_params.merge({ 'line_notice' => line_notice_attrs }) }

    before do
      if stub_policy
        fk_policy = double
        expect(fk_policy).to receive(:create?).with(Chouette::LineNotice).and_return(true)
        expect(Policy::Line).to receive(:new).with(line, context: anything).and_return(fk_policy)
      end
    end

    it 'should create a new line notice' do
      expect { request }.to(
        change { line.line_notices.count }.by(1) \
                                          .and(change { line_referential.line_notices.count }.by(1))
      )
    end

    it 'assigns default line provider' do
      request
      expect(line.line_notices.last.line_provider).to eq(workbench.default_line_provider)
    end

    it 'redirects to line line notices path' do
      request
      expect(response).to redirect_to workbench_line_referential_line_line_notice_memberships_path(workbench, line)
    end

    context 'with a line provider' do
      let(:line_notice_attrs) { base_line_notice_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }
      let(:stub_policy) { false }

      before { request }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it do
          expect(response).to redirect_to workbench_line_referential_line_line_notice_memberships_path(workbench, line)
        end
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end

    context 'of another workbench' do
      let(:line) { context.line(:other_line) }
      let(:stub_policy) { false }

      before { request }

      it { expect(response).to have_http_status(:not_found) }
    end
  end

  describe 'DELETE #destroy' do
    let(:request) { delete :destroy, params: base_params.merge({ 'id' => line_notice_membership.id.to_s }) }

    before { request }

    it { expect { line_notice_membership.reload }.to raise_error(ActiveRecord::RecordNotFound) }
    it { expect { line_notice_membership.line_notice.reload }.not_to raise_error }

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
