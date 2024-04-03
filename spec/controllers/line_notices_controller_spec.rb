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
        workbench(:other_workbench, organisation: organisation) do
          line :other_line
        end
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
          line_referential :first
          workbench :first, organisation: Organisation.find_by(code: 'first') do
            line_provider :first do
              line
              line_notice :first
              line_notice :second
            end
          end
        end
        workgroup(owner: Organisation.find_by(code: 'first')) do
          line_referential :other
          line_provider :other
          line_notice :other
        end
      end
    end

    let(:workbench) { context.workbench(:first) }
    let(:line_referential) { context.line_referential(:first) }
    let(:line_provider) { context.line_provider(:first) }
    let(:line) { context.line }
    let(:line_notices) { line_provider.line_notices }

    let(:other_line_referential) { context.line_referential(:other) }
    let(:other_line_provider) { context.line_provider(:other) }
    let(:other_line_notice) { context.line_notice(:other) }

    before do
      line_notices.second.lines << line
      other_line_notice.lines << line
    end

    it 'should be successful' do
      get :index, params: { workbench_id: workbench.id }
      expect(response).to be_successful
      expect(assigns(:line_notices)).to include(line_notices.first)
      expect(assigns(:line_notices)).to include(line_notices.last)
      expect(assigns(:line_notices)).to_not include(other_line_notice)
    end

    context "with filters" do
      let(:title_or_content_cont){ line_notices.first.title }
      let(:lines_id_eq){ line_notices.last.lines.first.id }

      it "should filter on title or content" do
        get :index, params: { workbench_id: workbench.id, q: {title_or_content_cont: title_or_content_cont} }
        expect(response).to be_successful
        expect(assigns(:line_notices)).to include(line_notices.first)
        expect(assigns(:line_notices)).to_not include(line_notices.last)
        expect(assigns(:line_notices)).to_not include(other_line_notice)
      end

      it "should filter by associated line id" do
        get :index, params: { workbench_id: workbench.id, q: {lines_id_eq: lines_id_eq} }
        expect(response).to be_successful
        expect(assigns(:line_notices)).to_not include(line_notices.first)
        expect(assigns(:line_notices)).to include(line_notices.last)
        expect(assigns(:line_notices)).to_not include(other_line_notice)
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

    context 'from a line' do
      let(:base_params) { { 'workbench_id' => workbench.id.to_s, 'line_id' => line.id.to_s } }

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

      context 'of another workbench' do
        let(:line) { context.line(:other_line) }
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

    context 'with a line provider' do
      let(:line_notice_attrs) { base_line_notice_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

      before { request }

      context 'of the current workbench' do
        let(:line_provider) { context.line_provider(:line_provider) }
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end

    context 'from a line' do
      let(:base_params) { { 'workbench_id' => workbench.id.to_s, 'line_id' => line.id.to_s } }

      it 'should create a new line notice' do
        expect { request }.to change { line_referential.line_notices.count }.by 1
      end

      it 'assigns default line provider' do
        request
        expect(line_referential.line_notices.last.line_provider).to eq(workbench.default_line_provider)
      end

      context 'with a line provider' do
        let(:line_notice_attrs) { base_line_notice_attrs.merge({ 'line_provider_id' => line_provider.id.to_s }) }

        before { request }

        context 'of the current workbench' do
          let(:line_provider) { context.line_provider(:line_provider) }
          it { expect(response).to have_http_status(:redirect) }
        end

        context 'of another workbench' do
          let(:line_provider) { context.line_provider(:other_line_provider) }
          it { expect(response).to have_http_status(:not_found) }
        end
      end

      context 'of another workbench' do
        let(:line) { context.line(:other_line) }
        before { request }
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

    context 'from a line' do
      let(:base_params) { { 'workbench_id' => workbench.id.to_s, 'line_id' => line.id.to_s } }

      it { is_expected.to render_template('line_notices/edit') }

      context 'when the line referential workbench is not the same as the current workbench' do
        let(:workbench) { context.workbench(:other_workbench) }
        it { expect(response).to have_http_status(:not_found) }
      end

      context 'when the line provider workbench is not the same as the current workbench' do
        let(:line_notice) { context.line_notice(:other_line_notice) }
        it { expect(response).to have_http_status(:forbidden) }
      end

      context 'when the line is not in current workbench line referential' do
        let(:line) { context.line(:other_line) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end

  describe 'PUT #update' do
    let(:request) do
      put :update, params: base_params.merge({ 'id' => line_notice.id.to_s, 'line_notice' => line_notice_attrs })
    end

    before { request }

    it { expect(response).to have_http_status(:redirect) }
    it { expect { line_notice.reload }.to change { line_notice.title }.to('test') }

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
        it { expect(response).to have_http_status(:redirect) }
      end

      context 'of another workbench' do
        let(:line_provider) { context.line_provider(:other_line_provider) }
        it { is_expected.to render_template('line_notices/edit') }
      end
    end

    context 'from a line' do
      let(:base_params) { { 'workbench_id' => workbench.id.to_s, 'line_id' => line.id.to_s } }

      it { expect(response).to have_http_status(:redirect) }
      it { expect { line_notice.reload }.to change { line_notice.title }.to('test') }

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
          it { expect(response).to have_http_status(:redirect) }
        end

        context 'of another workbench' do
          let(:line_provider) { context.line_provider(:other_line_provider) }
          it { is_expected.to render_template('line_notices/edit') }
        end
      end

      context 'when the line is not in current workbench line referential' do
        let(:line) { context.line(:other_line) }
        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end
end
