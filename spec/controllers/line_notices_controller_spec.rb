# frozen_string_literal: true

RSpec.describe LineNoticesController, type: :controller do
  login_user

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
  let!(:line) { context.line }
  let!(:line_notices) { line_provider.line_notices }

  let(:other_line_referential) { context.line_referential(:other) }
  let(:other_line_provider) { context.line_provider(:other) }
  let(:other_line_notice) { context.line_notice(:other) }

  before do
    line_notices.second.lines << line
    other_line_notice.lines << line
  end

  describe 'POST create' do
    let(:line_notice_attrs){{
      title: "test title",
      content: "test content"
    }}
    let(:request){ post :create, params: { workbench_id: workbench.id, line_notice: line_notice_attrs }}

    with_permission "line_notices.create" do
      it "should create a new line notice" do
        expect{request}.to change{ line_referential.line_notices.count }.by 1
      end

    end
  end

  describe "GET index" do
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

end
