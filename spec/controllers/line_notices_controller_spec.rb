# frozen_string_literal: true

RSpec.describe LineNoticesController, type: :controller do
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
          line_notice :other_line_notice, lines: [:line]
        end
      end
      workgroup do
        workbench(:other_workbench, organisation: organisation)
      end
    end
  end

  let(:workbench) { context.workbench(:workbench) }
  let(:line_referential) { workbench.line_referential }
  let(:line) { context.line(:line) }
  let(:line_notice) { context.line_notice(:line_notice) }

  let(:base_params) { { 'workbench_id' => workbench.id.to_s } }
  let(:base_line_notice_attrs) { { 'title' => 'test' } }
  let(:line_notice_attrs) { base_line_notice_attrs }

  before { @user.update(permissions: %w[line_notices.create line_notices.update line_notices.destroy]) }

  describe 'GET #index' do
    let(:context) do
      Chouette.create do
        workgroup(owner: Organisation.find_by(code: 'first')) do
          workbench :workbench, organisation: Organisation.find_by(code: 'first') do
            line_provider(:line_provider) do
              line :line
              line_notice :first
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
      expect(assigns(:line_notices)).to match_array(line_notices)
    end

    context 'with filters' do
      context 'on title or content' do
        let(:index_params) { base_params.merge({ q: { title_or_content_cont: line_notices.first.title } }) }

        it 'filters' do
          expect(response).to be_successful
          expect(assigns(:line_notices)).to match_array([line_notices.first])
        end
      end

      context 'by associated line id' do
        let(:index_params) { base_params.merge({ q: { lines_id_eq: line_notices.last.lines.first.id } }) }

        it 'filters' do
          expect(response).to be_successful
          expect(assigns(:line_notices)).to match_array([line_notices.last])
          expect(assigns(:filtered_line)).to eq(line_notices.last.lines.first)
        end
      end
    end
  end

  describe 'GET #new' do
    let(:request) { get :new, params: base_params }

    before { request }

    it { is_expected.to render_template('line_notices/new') }

    context 'when the params contain a line provider' do
      let(:request) do
        get :new, params: base_params.merge({ 'line_notice' => { 'line_provider_id' => line_provider.id.to_s } })
      end

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { is_expected.to render_template('line_notices/new') }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:request) { post :create, params: base_params.merge({ 'line_notice' => line_notice_attrs }) }

    it 'should create a new line notice' do
      expect { request }.to change { line_referential.line_notices.count }.by 1
    end

    it 'assigns default line provider' do
      request
      expect(line_referential.line_notices.last.line_provider).to eq(workbench.default_line_provider)
    end

    it 'redirects to line notices path' do
      request
      expect(response).to redirect_to workbench_line_referential_line_notices_path(workbench)
    end

    context 'with a line provider' do
      let(:line_notice_attrs) { base_line_notice_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

      before { request }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to redirect_to workbench_line_referential_line_notices_path(workbench) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'GET #edit' do
    let(:request) { get :edit, params: base_params.merge({ 'id' => line_notice.id.to_s }) }

    before { request }

    it { is_expected.to render_template('line_notices/edit') }

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:line_notice) { context.line_notice(:other_line_notice) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge({ 'id' => line_notice.id.to_s, 'line_notice' => line_notice_attrs })
    end

    before { request }

    it { expect { line_notice.reload }.to change { line_notice.title }.to('test') }

    it 'redirects to line notice path' do
      expect(response).to redirect_to workbench_line_referential_line_notice_path(workbench, line_notice)
    end

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:line_notice) { context.line_notice(:other_line_notice) }
      it { expect(response).to have_http_status(:forbidden) }
    end

    context 'when the params contain a line provider' do
      let(:line_notice_attrs) { base_line_notice_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to redirect_to workbench_line_referential_line_notice_path(workbench, line_notice) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { is_expected.to render_template('line_notices/edit') }
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:request) { delete :destroy, params: base_params.merge({ 'id' => line_notice.id.to_s }) }

    before { request }

    it { expect { line_notice.reload }.to raise_error(ActiveRecord::RecordNotFound) }

    it 'redirects to line notices path' do
      expect(response).to redirect_to workbench_line_referential_line_notices_path(workbench)
    end

    context 'when the line referential workbench is not the same as the current workbench' do
      let(:workbench) { context.workbench(:other_workbench) }
      it { expect(response).to have_http_status(:not_found) }
    end

    context 'when the line provider workbench is not the same as the current workbench' do
      let(:line_notice) { context.line_notice(:other_line_notice) }
      it { expect(response).to have_http_status(:forbidden) }
    end
  end
end
